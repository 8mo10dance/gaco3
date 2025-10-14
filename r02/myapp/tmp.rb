x0 = Shop.with_job_and_contract

# こっちは contract に関する条件が消える (より正確には、最後に追加した条件が消える)
x1 = x0.merge(Shop.where.has { not_exists(PublishLog.where.has { shop_id == shop.id }) })

# => SELECT \"shops\".* FROM \"shops\" WHERE EXISTS(SELECT \"jobs\".* FROM \"jobs\" WHERE \"jobs\".\"shop_id\" = \"shops\".\"id\") AND NOT EXISTS(SELECT \"publish_logs\".* FROM \"publish_logs\" WHERE \"publish_logs\".\"shop_id\" = \"shops\".\"id\")

# こっちは contract に関する条件が消えない
x2 = x0.where.has { not_exists(PublishLog.where.has { shop_id == shop.id }) }

# => SELECT \"shops\".* FROM \"shops\" WHERE EXISTS(SELECT \"jobs\".* FROM \"jobs\" WHERE \"jobs\".\"shop_id\" = \"shops\".\"id\") AND EXISTS(SELECT \"contracts\".* FROM \"contracts\" WHERE \"contracts\".\"id\" = \"shops\".\"contract_id\") AND NOT EXISTS(SELECT \"publish_logs\".* FROM \"publish_logs\" WHERE \"publish_logs\".\"shop_id\" = \"shops\".\"id\")
