#!/usr/bin/bash
  
#检查用户所用的bash
bash_dir=`which bash`
echo "The bash you are using is: ${bash_dir}, please notice! "

#设置下载路径变量
hadoop_url="https://mirrors.tuna.tsinghua.edu.cn/apache/hadoop/common/hadoop-2.7.6/hadoop-2.7.6.tar.gz"
hive_url="https://mirrors.tuna.tsinghua.edu.cn/apache/hive/hive-2.3.3/apache-hive-2.3.3-bin.tar.gz"
hbase_url="http://archive.apache.org/dist/hbase/1.2.0/hbase-1.2.0-bin.tar.gz"
kylin_url="https://mirrors.tuna.tsinghua.edu.cn/apache/kylin/apache-kylin-2.4.0/apache-kylin-2.4.0-bin-hbase1x.tar.gz"

#获取当前ip
current_ip=`ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`

#若捕获Ctrl+C，则执行onCtrlC函数
trap 'onCtrlC' INT
function onCtrlC(){
   #检查hdfs、yarn、historyserver、hbase是否运行，若运行，则先将其关闭
   if [ -n "`ps aux | grep hbase | grep -v grep`" ]
   then
      /root/kylin_trial/kylin_minimal_env/hbase-1.2.0/bin/stop-hbase.sh
   fi
   
   if [ -n "`ps aux | grep historyserver | grep -v grep`" ]
   then
      /root/kylin_trial/kylin_minimal_env/hadoop-2.7.6/sbin/mr-jobhistory-daemon.sh stop historyserver
   fi

   if [ -n "`ps aux | grep hdfs | grep -v grep`" ]
   then
      /root/kylin_trial/kylin_minimal_env/hadoop-2.7.6/sbin/stop-all.sh
   fi
   #删除/tmp目录下hadoop-*、hbase-*、Jetty_*、mapred-*、yarn-*相关的文件
   rm -rf /tmp/hadoop-* /tmp/hbase-* /tmp/Jetty_* /tmp/mapred-* /tmp/yarn-*
   #删除kylin_minimal_env
   rm -rf /root/kylin_trial/kylin_minimal_env
   echo ""
   echo "Installation is cancelled !"
   exit 0
}
#如果未能顺利安装，退出脚本并清理已有的文件
function if_download_fail(){
   if [ $? != 0 ]
   then
     rm -rf /root/kylin_trial/kylin_minimal_env
     echo ${1}
     exit 0
   fi
}

#修改hosts
if [ -z "`cat /etc/hosts | grep sandbox`" ]
then
   #若没有sandbox与ip的映射关系，则在hosts中追加
   echo "${current_ip} sandbox" >> /etc/hosts
   echo "Added \"ip sandbox\" to /etc/hosts"
else
   #否则更新sandbox与ip的映射关系
   sed "s/.* \([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\).*/\1/;s/[^0-9 ]*\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\).*sandbox/${current_ip} sandbox/g"  /etc/hosts > /etc/hosts_temp.txt
   cat /etc/hosts_temp.txt > /etc/hosts
   #删除临时文件
   rm -f /etc/hosts_temp.txt
   echo "updated \"ip sandbox\" in /etc/hosts"
fi

#disable "Are you sure you want to continue connecting (yes/no)? while" ssh localhost
echo "        StrictHostKeyChecking no" >> /etc/ssh/ssh_config
echo "        UserKnownHostsFile=/dev/null" >> /etc/ssh/ssh_config

#创建kylin_minimal_env并进入
echo "Dir kylin_minimal_env have been created ! "
mkdir kylin_minimal_env
echo "Enter kylin_minimal_env ! "
cd kylin_minimal_env

#记录kylin_minimal_env路径
kylin_minimal_env_dir=`pwd`

#设置环境变量
export HADOOP_HOME=${kylin_minimal_env_dir}/hadoop-2.7.6
export HIVE_HOME=${kylin_minimal_env_dir}/apache-hive-2.3.3-bin
export HBASE_HOME=${kylin_minimal_env_dir}/hbase-1.2.0
export KYLIN_HOME=${kylin_minimal_env_dir}/apache-kylin-2.4.0-bin-hbase1x
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin:$HBASE_HOME/bin:$KYLIN_HOME/bin:$PATH

#安装wget
wgetIsInstalled=$(yum list installed | grep wget)
if [ -n "${wgetIsInstalled}" ]
then
   echo "wget is installed! "
else
   yum -y install wget
fi

#下载hbase-1.2.0
echo "Download hbase-1.2.0:"
wget ${hbase_url}
if_download_fail "Download hbase failed !"
#下载hadoop-2.7.6
echo "Download hadoop-2.7.6: "
wget ${hadoop_url}
if_download_fail "Download hadoop failed !"
#下载hive-2.3.3
echo "Download hive-2.3.3: "
wget ${hive_url}
if_download_fail "Download hive failed !"
#下载kylin-2.4.0(for Hbase1.x)
echo "Download kylin-2.4.0(for Hbase1.x)"
wget ${kylin_url}
if_download_fail "Download kylin failed !"

#解压压缩包
tar -zxvf *hadoop-*.tar.gz
tar -zxvf *hive-*.tar.gz
tar -zxvf *hbase-*.tar.gz
tar -zxvf *kylin-*.tar.gz

#删除压缩包
rm -f *.tar.gz

#进入hadoop-2.7.6的配置文件目录
echo "Enter hadoop-2.7.6/etc/hadoop!"
cd hadoop-2.7.6/etc/hadoop
#创建mapred-site.xml
echo "Create mapred-site.xml"
cp mapred-site.xml.template mapred-site.xml

#配置yarn-site.xml
echo "<?xml version=\"1.0\"?> " > yarn-site.xml
echo "<!-- " >> yarn-site.xml
echo "  Licensed under the Apache License, Version 2.0 (the \"License\"); " >> yarn-site.xml
echo "  you may not use this file except in compliance with the License. " >> yarn-site.xml
echo "  You may obtain a copy of the License at " >> yarn-site.xml
echo " " >> yarn-site.xml
echo "    http://www.apache.org/licenses/LICENSE-2.0 " >> yarn-site.xml
echo " " >> yarn-site.xml
echo "  Unless required by applicable law or agreed to in writing, software " >> yarn-site.xml
echo "  distributed under the License is distributed on an \"AS IS\" BASIS, " >> yarn-site.xml
echo "  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. " >> yarn-site.xml
echo "  See the License for the specific language governing permissions and " >> yarn-site.xml
echo "  limitations under the License. See accompanying LICENSE file. " >> yarn-site.xml
echo "--> " >> yarn-site.xml
echo "<configuration> " >> yarn-site.xml
echo "<!-- Site specific YARN configuration properties --> " >> yarn-site.xml
echo "    <property> " >> yarn-site.xml
echo "        <name>yarn.nodemanager.aux-services</name> " >> yarn-site.xml
echo "        <value>mapreduce_shuffle</value> " >> yarn-site.xml
echo "    </property> " >> yarn-site.xml
echo "    <property> " >> yarn-site.xml
echo "        <name>yarn.resourcemanager.webapp.address</name> " >> yarn-site.xml
echo "        <value>sandbox:8088</value> " >> yarn-site.xml
echo "    </property> " >> yarn-site.xml
echo "</configuration> " >> yarn-site.xml

#配置mapred-site.xml
echo "Setting up mapred-site.xml!"
echo "<?xml version=\"1.0\"?>" > mapred-site.xml
echo "<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>" >> mapred-site.xml
echo "<!--" >> mapred-site.xml
echo "  Licensed under the Apache License, Version 2.0 (the \"License\");" >> mapred-site.xml
echo "  you may not use this file except in compliance with the License." >> mapred-site.xml
echo "  You may obtain a copy of the License at" >> mapred-site.xml
echo "" >> mapred-site.xml
echo "    http://www.apache.org/licenses/LICENSE-2.0" >> mapred-site.xml
echo "" >> mapred-site.xml
echo "  Unless required by applicable law or agreed to in writing, software" >> mapred-site.xml
echo "  distributed under the License is distributed on an \"AS IS\" BASIS," >> mapred-site.xml
echo "  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied." >> mapred-site.xml
echo "  See the License for the specific language governing permissions and" >> mapred-site.xml
echo "  limitations under the License. See accompanying LICENSE file." >> mapred-site.xml
echo "-->" >> mapred-site.xml
echo "" >> mapred-site.xml
echo "<!-- Put site-specific property overrides in this file. -->" >> mapred-site.xml
echo "" >> mapred-site.xml
echo "<configuration>" >> mapred-site.xml
echo "    <property>" >> mapred-site.xml
echo "        <name>mapreduce.framework.name</name>" >> mapred-site.xml
echo "        <value>yarn</value>" >> mapred-site.xml
echo "    </property>" >> mapred-site.xml
echo "   <property>" >> mapred-site.xml
echo "       <name>mapreduce.jobhistory.address</name>" >> mapred-site.xml
echo "       <value>sandbox:10020</value>" >> mapred-site.xml
echo "   </property>" >> mapred-site.xml
echo "   <property>" >> mapred-site.xml
echo "       <name>mapreduce.jobhistory.webapp.address	</name>" >> mapred-site.xml
echo "       <value>sandbox:19888</value>" >> mapred-site.xml
echo "   </property>" >> mapred-site.xml
echo "</configuration>" >> mapred-site.xml

#配置core-site.xml
echo "Setting up core-site.xml!"
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > core-site.xml
echo "<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>" >> core-site.xml
echo "<!--" >> core-site.xml
echo "  Licensed under the Apache License, Version 2.0 (the \"License\");" >> core-site.xml
echo "  you may not use this file except in compliance with the License." >> core-site.xml
echo "  You may obtain a copy of the License at" >> core-site.xml
echo "" >> core-site.xml
echo "    http://www.apache.org/licenses/LICENSE-2.0" >> core-site.xml
echo "" >> core-site.xml
echo "  Unless required by applicable law or agreed to in writing, software" >> core-site.xml
echo "  distributed under the License is distributed on an \"AS IS\" BASIS," >> core-site.xml
echo "  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied." >> core-site.xml
echo "  See the License for the specific language governing permissions and" >> core-site.xml
echo "  limitations under the License. See accompanying LICENSE file." >> core-site.xml
echo "-->" >> core-site.xml
echo "" >> core-site.xml
echo "<!-- Put site-specific property overrides in this file. -->" >> core-site.xml
echo "" >> core-site.xml
echo "<configuration>" >> core-site.xml
echo "    <property>" >> core-site.xml
echo "        <name>fs.defaultFS</name>" >> core-site.xml
echo "        <value>hdfs://sandbox:9000</value>" >> core-site.xml
echo "    </property>" >> core-site.xml
echo "    <property>" >> core-site.xml
echo "        <name>hadoop.proxyuser.root.hosts</name>" >> core-site.xml
echo "        <value>*</value>" >> core-site.xml
echo "    </property>" >> core-site.xml
echo "    <property>" >> core-site.xml
echo "        <name>hadoop.proxyuser.root.groups</name>" >> core-site.xml
echo "        <value>*</value>" >> core-site.xml
echo "    </property>" >> core-site.xml
echo "</configuration>" >> core-site.xml

#配置hdfs-site.xml
echo "Setting up hdfs-site.xml"
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > hdfs-site.xml
echo "<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>" >> hdfs-site.xml
echo "<!--" >> hdfs-site.xml
echo "  Licensed under the Apache License, Version 2.0 (the \"License\");" >> hdfs-site.xml
echo "  you may not use this file except in compliance with the License." >> hdfs-site.xml
echo "  You may obtain a copy of the License at" >> hdfs-site.xml
echo "" >> hdfs-site.xml
echo "    http://www.apache.org/licenses/LICENSE-2.0" >> hdfs-site.xml
echo "" >> hdfs-site.xml
echo "  Unless required by applicable law or agreed to in writing, software" >> hdfs-site.xml
echo "  distributed under the License is distributed on an \"AS IS\" BASIS," >> hdfs-site.xml
echo "  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied." >> hdfs-site.xml
echo "  See the License for the specific language governing permissions and" >> hdfs-site.xml
echo "  limitations under the License. See accompanying LICENSE file." >> hdfs-site.xml
echo "-->" >> hdfs-site.xml
echo "" >> hdfs-site.xml
echo "<!-- Put site-specific property overrides in this file. -->" >> hdfs-site.xml
echo "" >> hdfs-site.xml
echo "<configuration>" >> hdfs-site.xml
echo "    <property>" >> hdfs-site.xml
echo "        <name>dfs.replication</name>" >> hdfs-site.xml
echo "        <value>1</value>" >> hdfs-site.xml
echo "    </property>" >> hdfs-site.xml
echo "</configuration>" >> hdfs-site.xml

#设置Hadoop jdk环境
echo "export JAVA_HOME=${JAVA_HOME}" >> hadoop-env.sh

#返回kylin_minimal_env目录
cd "${kylin_minimal_env_dir}"

#格式化namenode
${kylin_minimal_env_dir}/hadoop-2.7.6/bin/hdfs namenode -format

#启动Hadoop
${kylin_minimal_env_dir}/hadoop-2.7.6/sbin/start-all.sh
#启动mr-jobhistroy
${kylin_minimal_env_dir}/hadoop-2.7.6/sbin/mr-jobhistory-daemon.sh start historyserver
#休眠8s，等待刚启动的HDFS渡过安全模式，以防止之后在HDFS中创建目录失败
echo "sleep 8s in case of \"Name node is in safe mode\""
sleep 8

#进入apache-hive-2.3.3-bin
cd apache-hive-2.3.3-bin
echo "Entered apache-hive-2.3.3-bin"
#创建目录iotmp
mkdir iotmp
#记录hive目录
hive_dir=`pwd`
#下载MySQL JDBC驱动，版本:8.0.11
wget https://cdn.mysql.com//Downloads/Connector-J/mysql-connector-java-8.0.11.tar.gz
if_download_fail "Download MySQL connector failed"
#解压缩
tar -zxvf mysql-connector-java-8.0.11.tar.gz
#将JDBC驱动放入lib目录下
mv ./mysql-connector-java-8.0.11/mysql-connector-java-8.0.11.jar lib
#删除下载文件
rm -rf mysql-connector-java-8.0.11*

#进入apache-hive-2.3.3-bin/conf目录
cd conf
#创建hive-site.xml
cp hive-default.xml.template hive-site.xml
#将hive-site.xml中的${system:java.io.tmpdir}设置为实际路径，并将结果输出至中间文件
sed "s#\${system:java.io.tmpdir}#${hive_dir}/iotmp#g" hive-site.xml > temp.txt
#修改hive metadata数据库JDBC信息
sed "s#jdbc\:derby\:\;databaseName=metastore_db\;create=true#jdbc\:mysql\://sandbox\:3306/hive_metastore?createDatabaseIfNotExist=true\&amp\;useSSL=false#g" temp.txt > hive-site.xml
#修改metadata数据库用户名
sed 's/<value>APP/<value>root/g' hive-site.xml > temp.txt
#修改metadata数据库连接密码
sed 's/<value>mine/<value>kylintest123/g' temp.txt > hive-site.xml
#修改metadata数据库的JDBC Driver名
sed 's/org.apache.derby.jdbc.EmbeddedDriver/com.mysql.cj.jdbc.Driver/g' hive-site.xml > temp.txt
#将修改完后的配置信息写入hive-site.xml
cat temp.txt > hive-site.xml
#删除临时文件temp.txt
rm -f temp.txt

#在HDFS中创建目录
echo "Create hive dir in HDFS"
${kylin_minimal_env_dir}/hadoop-2.7.6/bin/hadoop fs -mkdir -p /tmp
${kylin_minimal_env_dir}/hadoop-2.7.6/bin/hadoop fs -mkdir -p /user/hive/warehouse
${kylin_minimal_env_dir}/hadoop-2.7.6/bin/hadoop fs -chmod g+w /tmp
${kylin_minimal_env_dir}/hadoop-2.7.6/bin/hadoop fs -chmod g+w /user/hive/warehouse

#初始化schemal
echo "Init Schema"
${kylin_minimal_env_dir}/apache-hive-2.3.3-bin/bin/schematool -dbType mysql -initSchema

#返回kylin_minimal_env目录
cd "${kylin_minimal_env_dir}"
echo "Back to kylin_minimal_env!"

#进入apache-hive-2.3.3-bin/conf目录
cd hbase-1.2.0/conf
echo "<?xml version=\"1.0\"?>" > hbase-site.xml
echo "<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>" >> hbase-site.xml
echo "<!--" >> hbase-site.xml
echo "/**" >> hbase-site.xml
echo " *" >> hbase-site.xml
echo " * Licensed to the Apache Software Foundation (ASF) under one" >> hbase-site.xml
echo " * or more contributor license agreements.  See the NOTICE file" >> hbase-site.xml
echo " * distributed with this work for additional information" >> hbase-site.xml
echo " * regarding copyright ownership.  The ASF licenses this file" >> hbase-site.xml
echo " * to you under the Apache License, Version 2.0 (the" >> hbase-site.xml
echo " * \"License\"); you may not use this file except in compliance" >> hbase-site.xml
echo " * with the License.  You may obtain a copy of the License at" >> hbase-site.xml
echo " *" >> hbase-site.xml
echo " *     http://www.apache.org/licenses/LICENSE-2.0" >> hbase-site.xml
echo " *" >> hbase-site.xml
echo " * Unless required by applicable law or agreed to in writing, software" >> hbase-site.xml
echo " * distributed under the License is distributed on an \"AS IS\" BASIS," >> hbase-site.xml
echo " * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied." >> hbase-site.xml
echo " * See the License for the specific language governing permissions and" >> hbase-site.xml
echo " * limitations under the License." >> hbase-site.xml
echo " */" >> hbase-site.xml
echo "-->" >> hbase-site.xml
echo "<configuration>" >> hbase-site.xml
echo "  <property>" >> hbase-site.xml
echo "    <name>hbase.rootdir</name>" >> hbase-site.xml
echo "    <value>hdfs://sandbox:9000/hbase</value>" >> hbase-site.xml
echo "  </property>" >> hbase-site.xml
echo "  <property>" >> hbase-site.xml
echo "    <name>hbase.cluster.distributed</name>" >> hbase-site.xml
echo "    <value>false</value>" >> hbase-site.xml
echo "  </property>" >> hbase-site.xml
echo "</configuration>" >> hbase-site.xml

#在HDFS中创建相关目录
echo "Make dir /hbase in HDFS"
${kylin_minimal_env_dir}/hadoop-2.7.6/bin/hadoop fs -mkdir -p /hbase

#启动HBASE
${kylin_minimal_env_dir}/hbase-1.2.0/bin/start-hbase.sh
