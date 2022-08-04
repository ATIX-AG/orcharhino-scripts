#!/usr/bin/tfm-ruby
# frozen_string_literal: true

# (c) 2021 ATIX AG
# Author: Markus Bucher <bucher@atix.de>
#
# This script analyzes the candlepin-database and the katello-database to find
# missing product-content associations and propose SQL-commands to fix this.
# This script needs to be run by the 'root'-user!

require 'set'

def query_database(dbname, sql)
  res = []
  IO.popen("su - postgres -c 'psql #{dbname} -t -A -z'", 'w+') do |io|
    io.write sql
    io.close_write
    io.each_line do |line|
      res << line.strip.split("\0")
    end
  end
  res
end

def candlepin_db_exec(sql)
  query_database('candlepin', sql)
end

def foreman_db_exec(sql)
  query_database('foreman', sql)
end

def get_candlepin_product_content(product_cp_id)
  candlepin_db_exec("
SELECT content.name, content.content_id, content.contenturl,
       content.arches, content.requiredtags
  FROM cp_pool pool
  JOIN cp2_products product ON pool.product_uuid = product.uuid
  JOIN cp2_product_content pc ON product.uuid = pc.product_uuid
  JOIN cp2_content content ON content.uuid = pc.content_uuid
  WHERE product.product_id = '#{product_cp_id}'
;")
end

missing_cp_associations = candlepin_db_exec("
SELECT c.content_id, c.uuid, c.name
  FROM cp2_content c
  JOIN cp2_owner_content oc ON c.uuid=oc.content_uuid
  LEFT OUTER JOIN (
    SELECT pc.content_uuid
      FROM cp2_products p
      JOIN cp2_owner_products op ON p.uuid=op.product_uuid
      JOIN cp2_product_content pc ON p.uuid=pc.product_uuid
  ) x ON c.uuid = x.content_uuid
  WHERE x.content_uuid IS NULL;
")

missing_cp_associations.each do |entry|
  (content_id, content_uuid, content_name) = entry
  warn "Content name=#{content_name.inspect} w/o association;" \
       " content_uuid=#{content_uuid.inspect};" \
       " content_id=#{content_id.inspect}"
end
warn "\n"

candlepin_content_num_by_product = candlepin_db_exec("
SELECT product.product_id, product.uuid, product.product_id, COUNT(content.content_id)
  FROM cp_pool pool
  JOIN cp2_products product ON pool.product_uuid = product.uuid
  JOIN cp2_product_content pc ON product.uuid = pc.product_uuid
  JOIN cp2_content content ON content.uuid = pc.content_uuid
  GROUP BY product.uuid
;").map { |e| [e[0], e.drop(1)] }.to_h

foreman_content_num_by_product = foreman_db_exec("
SELECT p.cp_id, p.name, COUNT(c.id)
  FROM katello_products p
  JOIN katello_product_contents pc ON p.id = pc.product_id
  JOIN katello_contents c ON pc.content_id = c.id
  GROUP BY p.cp_id, p.name
;").map { |e| [e[0], e.drop(1)] }.to_h

look_closer_products = {}
foreman_content_num_by_product.each do |product_id, v|
  (name, num) = v
  next unless candlepin_content_num_by_product.key?(product_id)

  (uuid, _id, num_cp) = candlepin_content_num_by_product[product_id]
  next unless num != num_cp

  warn "Product #{name.inspect}(cp_id=#{product_id}) has #{num} content in foremanDB," \
       " but #{num_cp} content in candlepinDB"
  look_closer_products[product_id] = uuid
end

warn "\n"
warn "\n"

restore_cmds = []
# rubocop:disable Metrics/BlockLength
look_closer_products.each do |cp_id, product_uuid|
  katello_content_ids = foreman_db_exec("
SELECT c.cp_content_id
  FROM katello_products p
  JOIN katello_product_contents pc ON p.id = pc.product_id
  JOIN katello_contents c ON pc.content_id = c.id
  WHERE p.cp_id = '#{cp_id}'
;").flatten

  # get content_ids from candlepin
  cp_content_ids = get_candlepin_product_content(cp_id).map { |x| x[1] }

  missing_ids = katello_content_ids.to_set - cp_content_ids.to_set

  missing_ids.each do |content_id|
    missing = candlepin_db_exec("SELECT name, uuid FROM cp2_content WHERE content_id = '#{content_id}'")
    warn "\n"
    puts "-- repair missing: #{missing.map(&:first).uniq.inspect}"
    insert_sql = []
    missing.each do |content|
      (_content_name, content_uuid) = content
      insert_sql << "(REPLACE(uuid_in((md5((random())::text))::cstring)::text, '-', '' )," \
                    ' true,' \
                    " '#{product_uuid}'," \
                    " '#{content_uuid}'," \
                    ' NOW(), NOW())'
    end
    sql = 'INSERT INTO cp2_product_content (id, enabled, product_uuid, content_uuid, created, updated) ' \
          "VALUES #{insert_sql.join(', ')};"
    puts sql
    restore_cmds << sql

    # clear entity version of affected product to avoid versioning and convergence issues
    sql = "UPDATE cp2_products SET entity_version = NULL WHERE uuid = '#{product_uuid}';"
    puts sql

    restore_cmds << sql
  end
end
# rubocop:enable Metrics/BlockLength

if ARGV.include? '--repair'
  warn "\n"
  warn 'Repairing:'
  warn candlepin_db_exec("#{restore_cmds.join(';')};").inspect
end
