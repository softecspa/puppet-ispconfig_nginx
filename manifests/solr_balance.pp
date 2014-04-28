define ispconfig_nginx::solr_balance (
  $cluster_name    = '',
  $listen_ip,
  $sslcertname    = $clusterdomain,
  $htpasswd_path  = '/opt'
) {

  $clustername = $cluster_name?{
    ''      => $name,
    default => $cluster_name
  }

  $domain_name="solr-${clustername}.${clusterdomain}"

  sslterminus::domain{ $domain_name:
    listen_ip   => $listen_ip,
    proxy       => "http://solr-${clustername}",
    sslcertname => $sslcertname,
    lines       => [ "auth_basic \"Solr ${clustername} admin\";",
                     "auth_basic_user_file  ${htpasswd_path}/.htpasswd;"]
  }

  nginx::resource::location {"nginx-redir-${name}":
    vhost     => "nginx-vhost-$domain_name",
    location  => '= /',
    www_root  => '/var/www',
    lines     => [ 'return 301 $scheme://$host/solr$request_uri' ]
  }

  nginx::resource::upstream {"solr-${clustername}": }

  Nginx::Resource::Upstream_member <<| upstream == "solr-${clustername}" |>>

  #importa i frammenti per l'htpasswd
  concat {"${htpasswd_path}/.htpasswd":
    mode      => '640',
    owner     => 'root',
    group     => 'www-data',
  }
  Apache2::Htaccess_export <<| tag == 'nagios_htpasswd_softec_admin' |>> {
    filepath  => "${htpasswd_path}/.htpasswd"
  }
  Apache2::Htaccess_export <<| tag == 'nagios_htpasswd_softec_devel' |>> {
    filepath  => "${htpasswd_path}/.htpasswd"
  }
}
