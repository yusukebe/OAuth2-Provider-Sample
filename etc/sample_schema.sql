CREATE TABLE access_token (
    id INT UNSIGNED AUTO_INCREMENT,
    auth_id VARCHAR(255),
    token VARCHAR(255),
    expires_in INT UNSIGNED,
    created_on INT UNSIGNED,
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET 'utf8' engine=InnoDB;

CREATE TABLE auth_info (
    id INT UNSIGNED AUTO_INCREMENT,
    user_id VARCHAR(255),
    client_id VARCHAR(255),
    client_secret VARCHAR(255),
    scope VARCHAR(255),
    refresh_token VARCHAR(255),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET 'utf8' engine=InnoDB;

CREATE TABLE client (
    id INT UNSIGNED AUTO_INCREMENT,
    client_name VARCHAR(255),
    client_id VARCHAR(255),
    client_secret VARCHAR(255),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET 'utf8' engine=InnoDB;

CREATE TABLE user (
    id INT UNSIGNED AUTO_INCREMENT,
    user_name VARCHAR(255),
    password VARCHAR(255),
    PRIMARY KEY (`id`)
);
