<?php

/** The name of the database for WordPress */
define( 'DB_NAME', '${db_name}' );

/** MySQL database username */
define( 'DB_USER', '${db_user}' );

/** MySQL database password */
define( 'DB_PASSWORD', '${db_pass}' );

/** MySQL hostname */
define( 'DB_HOST', '${db_host}:${db_port}' );

/** Database Charset to use in creating database tables */
define( 'DB_CHARSET', 'utf8' );

/** The Database Collate type. Don't change this if in doubt */
define( 'DB_COLLATE', '' );

/** Used https://api.wordpress.org/secret-key/1.1/salt/ to generate values */
define('AUTH_KEY',         ']k_BSZ[ppzq>x8(/S,5-:E5?vD/hU+}pN+nf~O6?v{8laCWiz^&GkxfdmBTRD`$3');
define('SECURE_AUTH_KEY',  'UF)~@}<Nd]U19rk,[dv~7 qamC<e=a)-W@`_A%bw]LR +5HE$u7=DH$RRjt`h*v]');
define('LOGGED_IN_KEY',    'vZ}Z5M>Ejd]Ie*m`Gsm4|c{l4?X<@{C{oU;|C=j=p{:}l]&~-<64,n%Q4/kbCJIx');
define('NONCE_KEY',        '1Xo_{EQnj+f7`L^J,Y#FOH{6=h1Ucg7eQ|`26@SZo@2-l.?S_`z`Hu$yC89jWs5v');
define('AUTH_SALT',        '%Z-`M^+X*90,{cU(buNoaM=5D9H!Ft6<WfIv~0sK%<!b:e+^8j$gj$SDke+VEfw?');
define('SECURE_AUTH_SALT', '78d-g/`gx*Iy_2[wq42~g$W:$b6MF7<zV8`[B+:K%?7SS2Ir~-MeRsP/-*C+ueN.');
define('LOGGED_IN_SALT',   '-wh<#udo=NO4FleAxA=nW xbC[_BMb1=90[lM&Z~Vh-7Z/Wl|V7DwWVO@;r5j;7:');
define('NONCE_SALT',       'jyM&oU7V|I8C3Z?V71i.Iqx1|?-z%7q6l)Fbrn&FBC}m@b5&ns@jXs+8[HPA!_uJ');

define( 'WP_DEBUG', false );

if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', dirname( __FILE__ ) . '/' );
}

$table_prefix = 'wp_';

require_once( ABSPATH . 'wp-settings.php' );