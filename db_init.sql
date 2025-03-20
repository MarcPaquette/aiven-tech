-- Create a table and seed the data for replication

create table users (id serial primary key, username varchar(100));

insert into users (username) values ('Francesco'),('Ana'),('Floor');


/*
 * We need to implement a workaround because the defautl db user is not a super user.
 * https://aiven.io/docs/products/kafka/kafka-connect/howto/debezium-source-connector-pg#solve-the-error-must-be-superuser-to-create-for-all-tables-publication
 * https://gist.github.com/alexhwoods/4c4c90d83db3c47d9303cb734135130d
*/

CREATE EXTENSION aiven_extras CASCADE;
SELECT *
FROM aiven_extras.pg_create_publication_for_all_tables('dbz_publication', 'INSERT,UPDATE,DELETE');
