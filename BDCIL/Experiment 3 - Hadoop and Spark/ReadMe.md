# Experiment 3 $-$ Hadoop and Spark Setup
A little surprise for Z-Shell user at [the end](#a-sidenote)
## Pre-requistes
- Ubuntu device
- Stable internet connection ($\approx1.5\mathbb{GB}$ download)

## Steps
1. Open Ubuntu terminal (Keyboard shortcut: `Ctrl+Alt+T`).
2. Type in the commands to ensure the system is up-to-date.
	```bash
	sudo apt update
	# sudo apt upgrade # only if it is necessary
	```
3. After ensuring the system is up-to-date, install java installation (Required version: `JDK 17.x+`).
	```bash
	sudo apt-get install openjdk-17-jdk -y
	```
4. Setup environment variable `JAVA_HOME`.
	```bash
	echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc # ensure no spaces around =
	```
5. Update the path to include `JAVA_HOME` variable.
	```bash
	echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
	```
6. After installing java, we fetch the hadoop 3.4.1 gzip file.
	```bash
	wget https://dlcdn.apache.org/hadoop/common/hadoop-3.4.1/hadoop-3.4.1.tar.gz -P /tmp
	```
7. Extract the downloaded gzip file.
	```bash
	sudo tar -xzf /tmp/hadoop-3.4.1.tar.gz -C /opt/
	```
8. Create a symbolic link to refer to Hadoop.
	```bash
	sudo ln -sf /opt/hadoop-3.4.1 /opt/Hadoop
	```
9. Now we create `HADOOP_HOME` variable and update `PATH`.
	```bash
	echo 'export HADOOP_HOME=/opt/Hadoop' >> ~/.bashrc
	echo 'export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin' >> ~/.bashrc
	echo 'export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop' >> ~/.bashrc
	```
10. Reload the terminal using the command:
	```bash
	source ~/.bashrc
	```
	Or you can close and reopen the terminal
11. Now we create `namenode`(master node) and `datanode`(slave node).
	```bash
	mkdir -p ~/hadoop_data/namenode
	mkdir -p ~/hadoop_data/datanode
	sudo chown -R $USER:$USER ~/hadoop_data
	```
12. Now we configure several Hadoop XML files.
	- There are several ways to achieve this task.
	- The easiest way of them all is to use `sudo nano`.
	- Another way is to manually browse and update each file using built-in Text Editor (preferable) or Visual Studio Code (not-preferable).
	- Handy shortcuts for `nano`.
		- Paste text using `Ctrl+Shift+V`.
		- After you are done editing the file, either `Ctrl+S` to save then `Ctrl+X` to exit or `Ctrl+X` to save upon exit (answering Yes/No questions).
	- ***Important***: All files are stored at `$HADOOP_HOME/etc/hadoop/` directory (extended to `/opt/Hadoop/etc/hadoop/` using Files app).
	```xml
	<!-- core-site.xml -->
	<configuration>
		<property>
			<name>fs.defaultFS</name>
			<value>hdfs://localhost:9000</value>
		</property>
	</configuration>

	<!-- hdfs-site.xml -->
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

	<!-- mapred-site.xml -->
	<configuration>
		<property>
			<name>mapreduce.framework.name</name>
			<value>yarn</value>
		</property>
	</configuration>

	<!-- yarn-site.xml -->
	<configuration>
		<property>
			<name>yarn.nodemanager.aux-services</name>
			<value>mapreduce_shuffle</value>
		</property>
	</configuration>
	```
13. Once all files are set up, format Hadoop NameNode
	```bash
	hdfs namenode -format
	```
	- If encoutered the error `cannot create logs directory`.
	```bash
	sudo mkdir -p /opt/Hadoop/logs
	sudo chown -R $USER:$USER /opt/Hadoop/logs
	sudo chmod -R 755 /opt/Hadoop/logs
	sudo chown -R $USER:$USER /opt/hadoop
	# sudo chown -R /home/USER_NAME/hadoop_data
	```
	Then try again.
14. _(Optional step, if the next step raises SSH error)_ Setup SSH.
	```bash
	sudo apt install ssh -y
	ssh-keygen -t rsa -P "" # Hit Enter
	ssh-copy-id "$(whoami)@$(hostname)"
	chmod 700 ~/.ssh
	chmod 600 ~/.ssh/authorized_keys
	```
15. We finally start Hadoop Services.
	```bash
	start-dfs.sh
	start-yarn.sh
	```
	- If `SSH` error occurs, go back to Step 14.
	- If `JAVA NOT FOUND` error:
	```bash
	sudo chown -R $USER:$USER $HADOOP_HOME/etc/hadoop/hadoop-env.sh
	echo "export JAVA_HOME=$JAVA_HOME" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
	```
	- If services are already running, we need to `kill` them and clear their `.pid` files.
		- Syntax of `kill` command = `kill {PID}`
	- Usually, the `.pid` files are stored in /tmp/hadoop-{USER-NAME}-*.pid
16. After all these steps, we verify that HDFS is running
	```bash
	hdfs dfs -mkdir /user || true
	hdfs dfs -mkdir /user/$USER || true
	hdfs dfs -ls /
	echo "Hello Hadoop" > hello.txt
	hdfs dfs -put -f hello.txt /user/$USER/
	hdfs dfs -cat /user/$USER/hello.txt
	```
	- This should output a bunch of things, and at the end, it should print `Hello Hadoop`.
	- If any error is faced, make sure to remove `hdfs-cli` or `hadoop-cli` package if installed:
	```bash
	sudo apt remove hdfs-cli hadoop-cli
	```
17. Finally, we download Spark.
	```bash
	wget https://dlcdn.apache.org/spark/spark-4.0.0/spark-4.0.0-bin-hadoop3.tgz -P /tmp
	```
18. Extract the downloaded file.
	```bash
	sudo tar -xzf /tmp/spark-4.0.0-bin-hadoop3.tgz -C /opt/
	sudo ln -sf /opt/spark-4.0.0-bin-hadoop3 /opt/Spark
	```
19. Set environment variables
	```bash
	echo 'export SPARK_HOME=/opt/Spark' >> ~/.bashrc
	echo 'export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin' >> ~/.bashrc
	source ~/.bashrc # or reopen the terminal
	```
20. Test Spark Shell
	```bash
	spark-shell --version
	```
	- If error is raised, ensure you have JDK 17.x+ (Step 3)
21. Test Spark & Hadoop Integration
	```bash
	echo "==== 11. Test Spark & Hadoop Integration ===="
	spark-submit --class org.apache.spark.examples.SparkPi \
	$SPARK_HOME/examples/jars/spark-examples_2.12-4.0.0.jar 10
	```
22. Check the output at
	- HDFS NameNode UI: <http://localhost:9870>
	- YARN ResourceManager UI: <http://localhost:8088>
	- Spark UI: <http://localhost:4040>

---
The implementation part is complete, the content below is explanation for a robust automated script that will setup Hadoop and Spark executing all the given steps.
## The automated script is at [here!][1]
### Explanation of the script working
```bash
#!/bin/bash

# Hadoop & Spark Setup Script for Ubuntu 20.04/22.04
# Removes previous installations and env variables, and auto-installs packages.
set +e
```
- The first part initializes the shell file to use `bin/bash`
- The `set +e` flag is used to keep the script alive even after an error occurs to ensure possibility of debugging.
---
```bash
echo "==== 1. Clean previous installations ===="
sudo rm -rf /opt/hadoop /opt/hadoop-3.4.1 /opt/Spark /opt/spark-4.0.-bin-hadoop3 ~/hadoop_data
echo "Removing Environment variables"
sed -i '/export HADOOP_HOME/d' ~/.bashrc
sed -i '/export HADOOP_CONF_DIR/d' ~/.bashrc
sed -i '/export SPARK_HOME/d' ~/.bashrc
sed -i '/HADOOP_HOME\/bin/d' ~/.bashrc
sed -i '/HADOOP_HOME\/sbin/d' ~/.bashrc
sed -i '/SPARK_HOME\/bin/d' ~/.bashrc
sed -i '/SPARK_HOME\/sbin/d' ~/.bashrc
sed -i '/JAVA_HOME/d' ~/.bashrc
```
- This part cleans up any previous Hadoop & Spark installations and removes environment variables. (To enable a fresh start.)
---
```bash
echo "==== 2. Install Java JDK 17+ ===="
sudo apt-get update -y
sudo apt-get install openjdk-17-jdk -y
echo "Java JDK 17+ installed successfully. Now setting environment variables"
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```
- This part installs the Java JDK 17+ version and sets it's environment variable.
---
```bash
echo "==== 3. Download and Install Hadoop 3.4.1 ===="
sudo mkdir -p /opt/hadoop
sudo chown -R $USER:$USER /opt/hadoop
FILE="/tmp/hadoop-3.4.1.tar.gz"
if [ ! -f "$FILE" ]; then
	echo "File not found. Downloading Hadoop..."
	wget https://dlcdn.apache.org/hadoop/common/hadoop-3.4.1/hadoop-3.4.1.tar.gz -P /tmp
else
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
```
- This crucial part does 2 main things:
	- It checks for `hadoop-3.4.1.tar.gz` file in `/tmp/` directory, if it exists, the code skips the download (saving time), else it downloads the file.
	- It then extracts and creates a symbolic link and then sets some environment variables.
---
```bash
echo "==== 4. Create HDFS Data Directories ===="
mkdir -p ~/hadoop_data/namenode
mkdir -p ~/hadoop_data/datanode
sudo chown -R $USER:$USER ~/hadoop_data
```
- This part only creates Data Directories required by Hadoop.
---
```bash
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
```
- This is the most crucial part that is automated, it executes in the following steps:
	1. It grants ownership to all `.xml` files in `$HADOOP_HOME/etc/hadoop` directory.
	2. It then updates the required XML files with the proper content.
	3. It preserves the indentations in the files due to EOL.
---
```bash
echo "==== 6. Format Hadoop NameNode ===="
sudo apt remove hadoop-cli -y
sudo apt remove hdfs-cli -y
sudo mkdir -p /opt/Hadoop/logs
sudo chown -R $USER:$USER /opt/Hadoop/logs
sudo chmod -R 755 /opt/Hadoop/logs
sudo chown -R $USER:$USER /opt/hadoop
sudo chown -R /home/ubuntu/hadoop_data
yes | hdfs namenode -format
```
- It is essential to remove any hadoop-cli or hdfs-cli packages installed in the system, before fomatting namenode.
- This takes care of all possible errors due to the format command to format the namenode(master node).
---
```bash
echo "==== Prerequisite for 7. SSH Stuff ===="
sudo apt install ssh -y
ssh-keygen -t rsa -P ""
ssh-copy-id "$(whoami)@$(hostname)"
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```
- This step sets up ssh keys.
- This step is pre-requisite to the next step.
```bash
echo "==== 7. Start Hadoop Services ===="
# Automatically insert or update JAVA_HOME in hadoop-env.sh
sudo chown -R $USER:$USER $HADOOP_HOME/etc/hadoop/hadoop-env.sh
sudo sed -i.bak "/^export JAVA_HOME=/d" $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
echo "export JAVA_HOME=$JAVA_HOME" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
echo "✅ JAVA_HOME has been set to '$JAVA_HOME' in hadoop-env.sh"

for pidfile in /tmp/hadoop-$(whoami)-*.pid; do
    [ -f "$pidfile" ] || continue
    pid=$(cat "$pidfile")
    echo "Found PID $pid in $pidfile"
    
    if kill -0 "$pid" 2>/dev/null; then
        echo "Killing process $pid"
        kill -9 "$pid"
    else
        echo "Process $pid not running"
    fi
    
    echo "Removing $pidfile"
    rm -f "$pidfile"
done

yes | start-dfs.sh
yes | start-yarn.sh
```
- This portion adds `JAVA_HOME` variable to `$HADOOP_HOME/etc/hadoop/hadoop-env.sh`.
- It then starts the dfs and yarn nodes.
---
```bash
echo "==== 8. Verify HDFS ===="
hdfs dfs -mkdir /user || true
hdfs dfs -mkdir /user/$USER || true
hdfs dfs -ls /
echo "Hello Hadoop" > hello.txt
hdfs dfs -put -f hello.txt /user/$USER/
hdfs dfs -cat /user/$USER/hello.txt
```
- This portion just tests the HDFS working by creating a `/user` directory and making a `hello.txt` file with the text `Hello Hadoop` and then writing it to the `STDOUT` using `cat` command.
---
```bash
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
```
- This step is similar to Hadoop setup.
	- It checks for the `spark-4.0.0-bin-hadoop3.tgz` file.
	- Skips download if it already exists. Else, it downloads the file.
	- Extract, create symbolic link and set environment variables and restart the shell.
---
```bash
echo "==== 10. Test Spark Shell ===="
yes | spark-shell --version
```
- Test Spark Shell, in order to check Spark installation 
---
```bash
echo "==== 11. Test Spark & Hadoop Integration ===="
spark-submit --class org.apache.spark.examples.SparkPi \
$SPARK_HOME/examples/jars/spark-examples_2.12-4.0.0.jar 10
```
- This part tests the integration of Spark & Hadoop, by executing an example jar (which calculates the value of $\pi$ using `10` random points, passed in the command).
---
```bash
echo "==== Hadoop & Spark Setup Complete ===="
echo "Test Web UIs:"
echo "- HDFS NameNode UI: http://localhost:9870"
echo "- YARN ResourceManager UI: http://localhost:8088"
echo "- Spark UI: http://localhost:4040"
```
- This final portion summarises and lists important ports for different resources to monitor

## A sidenote
**PS:** If you are a [Z Shell](https://ohmyz.sh/) user like me, you might find this [script](2) helpful! (Just replaced every `.bashrc` with `.zshrc` <3).

[1]: ./hadoop_setup_bash.sh
[2]: ./hadoop_setup_zsh.sh