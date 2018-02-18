REM Add the required users for ZooKeeper
  
net user zookeeper-0-server MesosphereAD2018 /add /expires:NEVER /domain /yes
net user zookeeper-1-server MesosphereAD2018 /add /expires:NEVER /domain /yes
net user zookeeper-2-server MesosphereAD2018 /add /expires:NEVER /domain /yes
  
REM Add the required users for Kafka
  
net user kafka-0-broker MesosphereAD2018 /add /expires:NEVER /domain /yes
net user kafka-1-broker MesosphereAD2018 /add /expires:NEVER /domain /yes
net user kafka-2-broker MesosphereAD2018 /add /expires:NEVER /domain /yes
  
REM Add a client
  
net user client MesosphereAD2018 /add /expires:NEVER /domain /yes
  
REM Create a keytab with all principals
  
ktpass.exe                          /princ kafka/kafka-0-broker.cl3453-beta-confluent-kafka.autoip.dcos.thisdcos.directory@ad.mesosphere.com /mapuser kafka-0-broker@ad.mesosphere.com /ptype KRB5_NT_PRINCIPAL /pass MesosphereAD2018 /out brokers-0.keytab
ktpass.exe /in brokers-0.keytab     /princ kafka/kafka-1-broker.cl3453-beta-confluent-kafka.autoip.dcos.thisdcos.directory@ad.mesosphere.com /mapuser kafka-1-broker@ad.mesosphere.com /ptype KRB5_NT_PRINCIPAL /pass MesosphereAD2018 /out brokers-1.keytab
ktpass.exe /in brokers-1.keytab     /princ kafka/kafka-2-broker.cl3453-beta-confluent-kafka.autoip.dcos.thisdcos.directory@ad.mesosphere.com /mapuser kafka-2-broker@ad.mesosphere.com /ptype KRB5_NT_PRINCIPAL /pass MesosphereAD2018 /out cl3453-brokers.keytab
ktpass.exe                          /princ client@ad.mesosphere.com /mapuser client@ad.mesosphere.com /ptype KRB5_NT_PRINCIPAL /pass MesosphereAD2018 /out cl3453-clients.keytab
ktpass.exe                          /princ zookeeper/zookeeper-0-server.cl3453-beta-confluent-kafka-zookeeper.autoip.dcos.thisdcos.directory@ad.mesosphere.com /mapuser zookeeper-0-server@ad.mesosphere.com /ptype KRB5_NT_PRINCIPAL /pass MesosphereAD2018 /out zk-0.keytab
ktpass.exe /in zk-0.keytab          /princ zookeeper/zookeeper-1-server.cl3453-beta-confluent-kafka-zookeeper.autoip.dcos.thisdcos.directory@ad.mesosphere.com /mapuser zookeeper-1-server@ad.mesosphere.com /ptype KRB5_NT_PRINCIPAL /pass MesosphereAD2018 /out zk-1.keytab
ktpass.exe /in zk-1.keytab          /princ zookeeper/zookeeper-2-server.cl3453-beta-confluent-kafka-zookeeper.autoip.dcos.thisdcos.directory@ad.mesosphere.com /mapuser zookeeper-2-server@ad.mesosphere.com /ptype KRB5_NT_PRINCIPAL /pass MesosphereAD2018 /out cl3453-zookeeper.keytab