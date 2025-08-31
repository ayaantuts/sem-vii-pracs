#!/bin/bash

# Hadoop & Spark Setup Script for Ubuntu 20.04/22.04
# Removes previous installations and env variables, and auto-installs packages.
set +e

echo "==== 1. Clean previous installations ===="
sudo apt remove hadoop-cli hdfs-cli -y
# Remove Hadoop & Spark folders if they exist
sudo rm -rf /opt/hadoop /opt/hadoop-3.4.1 /opt/Spark /opt/spark-4.0.-bin-hadoop3 ~/hadoop_data

# Remove Hadoop/Spark env variables from ~/.bashrc
echo "Removing Environment variables"
sed -i '/export HADOOP_HOME/d' ~/.bashrc
sed -i '/export HADOOP_CONF_DIR/d' ~/.bashrc
sed -i '/export SPARK_HOME/d' ~/.bashrc
sed -i '/HADOOP_HOME\/bin/d' ~/.bashrc
sed -i '/HADOOP_HOME\/sbin/d' ~/.bashrc
sed -i '/SPARK_HOME\/bin/d' ~/.bashrc
sed -i '/SPARK_HOME\/sbin/d' ~/.bashrc
sed -i '/JAVA_HOME/d' ~/.bashrc

echo "==== 2. Install Java JDK 17+ ===="
sudo apt-get update -y
sudo apt-get install openjdk-17-jdk -y
echo "Java JDK 17+ installed successfully. Now setting environment variables"
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc
# echo 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin' >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

echo "==== 3. Download and Install Hadoop 3.4.1 ===="
sudo mkdir -p /opt/hadoop
sudo chown -R $USER:$USER /opt/hadoop
FILE="/tmp/hadoop-3.4.1.tar.gz"
if [ ! -f "$FILE" ]; then
	echo "File not found. Downloading Hadoop..."
	wget https://dlcdn.apache.org/hadoop/common/hadoop-3.4.1/hadoop-3.4.1.tar.gz -P /tmp
else
	# If the file exists, print a message
	echo "File already exists. Skipping download."
fi
echo "Extracting the file"
sudo tar -xzf /tmp/hadoop-3.4.1.tar.gz -C /opt/
echo "Creating symbolic link"
sudo ln -sf /opt/hadoop-3.4.1 /opt/Hadoop

echo "Setting Environment variables"
echo 'export HADOOP_HOME=/opt/Hadoop' >> ~/.bashrc
echo 'export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin' >> ~/.bashrc
echo 'export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop' >> ~/.bashrc
source ~/.bashrc

echo "==== 4. Create HDFS Data Directories ===="
mkdir -p ~/hadoop_data/namenode
mkdir -p ~/hadoop_data/datanode
sudo chown -R $USER:$USER ~/hadoop_data

echo "==== 5. Configure Hadoop XML files ===="
sudo chown $USER:$USER $HADOOP_HOME/etc/hadoop/*.xml
echo "Updating core-site.xml"
# Update core-site.xml
sudo cat > $HADOOP_HOME/etc/hadoop/core-site.xml <<EOL
<configuration>
	<property>
		<name>fs.defaultFS</name>
		<value>hdfs://localhost:9000</value>
	</property>
</configuration>
EOL

echo "Updating hdfs-site.xml"
# Update hdfs-site.xml
sudo cat > $HADOOP_HOME/etc/hadoop/hdfs-site.xml <<EOL
<configuration>
	<property>
		<name>dfs.namenode.name.dir</name>
		<value>file://$HOME/hadoop_data/namenode</value>
	</property>
	<property>
		<name>dfs.datanode.data.dir</name>
		<value>file://$HOME/hadoop_data/datanode</value>
	</property>
	<property>
		<name>dfs.replication</name>
		<value>1</value>
	</property>
</configuration>
EOL

echo "Updating mapred-site.xml"
# mapred-site.xml
# cp $HADOOP_HOME/etc/hadoop/mapred-site.xml.template $HADOOP_HOME/etc/hadoop/mapred-site.xml
sudo cat > $HADOOP_HOME/etc/hadoop/mapred-site.xml <<EOL
<configuration>
	<property>
		<name>mapreduce.framework.name</name>
		<value>yarn</value>
	</property>
</configuration>
EOL

echo "Updating yarn-site.xml"
# yarn-site.xml
sudo cat > $HADOOP_HOME/etc/hadoop/yarn-site.xml <<EOL
<configuration>
	<property>
		<name>yarn.nodemanager.aux-services</name>
		<value>mapreduce_shuffle</value>
	</property>
</configuration>
EOL

echo "==== 6. Format Hadoop NameNode ===="
sudo mkdir -p /opt/Hadoop/logs
sudo chown -R $USER:$USER /opt/Hadoop/logs
sudo chmod -R 755 /opt/Hadoop/logs
sudo chown -R $USER:$USER /opt/hadoop
sudo chown -R /home/ubuntu/hadoop_data
yes | hdfs namenode -format

echo "==== Prerequisite for 7. SSH Stuff ===="
sudo apt install ssh -y
ssh-keygen -t rsa -P ""
ssh-copy-id "$(whoami)@$(hostname)"
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

echo "==== 7. Start Hadoop Services ===="
# Automatically insert or update JAVA_HOME in hadoop-env.sh
sudo chown -R $USER:$USER $HADOOP_HOME/etc/hadoop/hadoop-env.sh
sudo sed -i.bak "/^export JAVA_HOME=/d" $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
echo "export JAVA_HOME=$JAVA_HOME" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
echo "✅ JAVA_HOME has been set to '$JAVA_HOME' in hadoop-env.sh"

for pidfile in /tmp/hadoop-$(whoami)-*.pid; do
	[ -f "$pidfile" ] || continue
	pid=$(cat "$pidfile")
	echo "🔍 Found PID $pid in $pidfile"
	if kill -0 "$pid" 2>/dev/null; then
		echo "🛑 Killing process $pid"
		kill -9 "$pid"
	else
		echo "⚠️ Process $pid not running"
	fi
	echo "🧹 Removing $pidfile"
	rm -f "$pidfile"
done

yes | start-dfs.sh
yes | start-yarn.sh

echo "==== 8. Verify HDFS ===="
hdfs dfs -mkdir /user || true
hdfs dfs -mkdir /user/$USER || true
hdfs dfs -ls /
echo "Hello Hadoop" > hello.txt
hdfs dfs -put -f hello.txt /user/$USER/
hdfs dfs -cat /user/$USER/hello.txt

echo "==== 9. Download and Install Spark 3.4.1 ===="
FILE2="/tmp/spark-4.0.0-bin-hadoop3.tgz"
if [ ! -f "$FILE2" ]; then
	echo "File not found. Downloading Spark..."
	wget https://dlcdn.apache.org/spark/spark-4.0.0/spark-4.0.0-bin-hadoop3.tgz -P /tmp
else
	# If the file exists, print a message
	echo "File already exists. Skipping download."
fi
sudo tar -xzf /tmp/spark-4.0.0-bin-hadoop3.tgz -C /opt/
sudo ln -sf /opt/spark-4.0.0-bin-hadoop3 /opt/Spark

echo 'export SPARK_HOME=/opt/Spark' >> ~/.bashrc
echo 'export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin' >> ~/.bashrc
source ~/.bashrc

echo "==== 10. Test Spark Shell ===="
yes | spark-shell --version

echo "==== 11. Test Spark & Hadoop Integration ===="
spark-submit --class org.apache.spark.examples.SparkPi \
$SPARK_HOME/examples/jars/spark-examples_2.12-4.0.0.jar 10

echo "==== Hadoop & Spark Setup Complete ===="
echo "Test Web UIs:"
echo "- HDFS NameNode UI: http://localhost:9870"
echo "- YARN ResourceManager UI: http://localhost:8088"
echo "- Spark UI: http://localhost:4040"