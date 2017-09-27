#!/bin/bash

################################ Modification of SQL Files ################################
echo "
CREATE TABLE usvn_files_rights
        (
                projects_id integer not null,
                files_rights_path text,
                files_rights_id integer primary key AUTO_INCREMENT
        );
ALTER TABLE usvn_files_rights ADD INDEX to_belong_fk(projects_id);
CREATE TABLE usvn_groups
        (
                groups_name varchar(150) not null,
                groups_description varchar(1000),
                groups_id integer primary key AUTO_INCREMENT
        );
CREATE TABLE usvn_groups_to_files_rights
        (
                files_rights_is_readable boolean not null,
                files_rights_is_writable boolean not null,
                files_rights_id integer not null,
                groups_id integer not null,
                primary key (files_rights_id, groups_id)
        );
ALTER TABLE usvn_groups_to_files_rights ADD INDEX usvn_groups_to_files_rights_fk(files_rights_id);
ALTER TABLE usvn_groups_to_files_rights ADD INDEX usvn_groups_to_files_rights2_fk(groups_id);
CREATE TABLE usvn_groups_to_projects
        (
                groups_id integer not null,
                projects_id integer not null,
                primary key (projects_id, groups_id)
        );
ALTER TABLE usvn_groups_to_projects ADD INDEX usvn_groups_to_projects_fk(projects_id);
ALTER TABLE usvn_groups_to_projects ADD INDEX usvn_groups_to_projects2_fk(groups_id);
CREATE TABLE usvn_projects
        (
                projects_name varchar(255) not null,
                projects_start_date datetime not null,
                projects_description varchar(1000),
                projects_id integer primary key AUTO_INCREMENT,
                CONSTRAINT PROJECTS_NAME_UNQ UNIQUE (projects_name)
        );
CREATE TABLE usvn_users
        (
                users_login varchar(255) not null,
                users_password varchar(64) not null,
                users_lastname varchar(100),
                users_firstname varchar(100),
                users_email varchar(150),
                users_is_admin boolean not null,
                users_id integer primary key AUTO_INCREMENT,
                users_secret_id varchar(32),
 users_secret_id varchar(32),
                CONSTRAINT USERS_LOGIN_UNQ UNIQUE (users_login)
);
CREATE TABLE usvn_users_to_groups
        (
                users_id integer not null,
                groups_id integer not null,
                is_leader boolean not null,
                primary key (users_id, groups_id)
        );
ALTER TABLE usvn_users_to_groups ADD INDEX users_to_groups_fk (users_id);
ALTER TABLE usvn_users_to_groups ADD INDEX users_to_groups2_fk (groups_id);
CREATE TABLE usvn_users_to_projects
        (
                users_id integer not null,
                projects_id integer not null,
                primary key (projects_id, users_id)
        );
ALTER TABLE usvn_users_to_projects ADD INDEX users_to_projects_fk (projects_id);
ALTER TABLE usvn_users_to_projects ADD INDEX users_to_projects2_fk (users_id);
alter table usvn_files_rights add constraint fk_usvn_file_rights foreign key (projects_id) references usvn_projects (projects_id) on delete restrict on update restrict;
alter table usvn_groups_to_files_rights add constraint fk_usvn_groups_to_files_rights foreign key (files_rights_id) references usvn_files_rights (files_rights_id) on delete restrict on update restrict;
alter table usvn_groups_to_files_rights add constraint fk_usvn_groups_to_files_rights2 foreign key (groups_id) references usvn_groups (groups_id) on delete restrict on update restrict;
alter table usvn_groups_to_projects add constraint fk_usvn_groups_to_projects foreign key (projects_id) references usvn_projects (projects_id) on delete restrict on update restrict;
alter table usvn_groups_to_projects add constraint fk_usvn_groups_to_projects2 foreign key (groups_id) references usvn_groups (groups_id) on delete restrict on update restrict;
alter table usvn_users_to_groups add constraint fk_usvn_users_to_groups foreign key (users_id) references usvn_users (users_id) on delete restrict on update restrict;
alter table usvn_users_to_groups add constraint fk_usvn_users_to_groups2 foreign key (groups_id) references usvn_groups (groups_id) on delete restrict on update restrict;
alter table usvn_users_to_projects add constraint fk_usvn_users_to_projects foreign key (projects_id) references usvn_projects (projects_id) on delete restrict on update restrict;
alter table usvn_users_to_projects add constraint fk_usvn_users_to_projects2 foreign key (users_id) references usvn_users (users_id) on delete restrict on update restrict;" > /usr/local/lib/usvn/app/install/sql/mysql.sql
