# update dependencies
sudo apt update -y

# check if apache is already install or install
if [ $(dpkg --get-selections | grep -i apache2 | grep -vc grep) -ge 0 ];then
	echo "Apache2 is already installed."
else
	sudo apt install apache2 -y
fi

# check if apacahe is already running or restart the services
if [ $(sudo systemctl status apache2.service | grep -i active | grep -vc grep) -eq 0 ];then
	echo "Apache2 is not running! Restarting the service"
	sudo systemctl restart apache2.service
fi

# creating the folder and copying the logs 
myname=prudhvi

timestamp=$(date '+%d%m%Y-%H%M%S')
cd /var/log/apache2/ 
logs_folder=/tmp/${myname}-httpd-logs-${timestamp}

mkdir -p ${logs_folder}
cp *.log ${logs_folder}

# archiving the folder
tar -cf ${logs_folder}.tar ${logs_folder} > /dev/null

# install aws cli
sudo apt install awscli -y

# pushing the archive to the s3 bucket
s3_bucket=upgrad-prudhvi-reddy
aws s3 \
cp /tmp/${myname}-httpd-logs-${timestamp}.tar \
s3://${s3_bucket}/${myname}-httpd-logs-${timestamp}.tar

# checking script status 
if [ $? -eq 0 ];then
	echo "logs archive file successfully uploaded to storage s3://${s3_bucket}"
fi

# create inventory file
if [ -e /var/www/html/inventory.html ]
then
	echo "Inventory file found"
else 
	touch /var/www/html/inventory.html
	echo "<table>
    <tr>
        <th>Log Type</th>
        <th>Time Created</th> 
        <th>Type</th>  
        <th>Size</th>
    </tr>
    </table>" >> /var/www/html/inventory.html

fi
 
sed -i '$d' /var/www/html/inventory.html

echo "<tr>
        <td>httpd-logs</td>
        <td>${timestamp}</td>
        <td>tar</td>
        <td>`du -h /tmp/${myname}-httpd-logs-${timestamp}.tar | awk '{print $1}'`</td>
    </tr>
    </table>" >>  /var/www/html/inventory.html


if [ -e /etc/cron.d/automation ]
then
        echo "cron job found"
else
        touch /etc/cron.d/automation
        echo "0 0 * * * root /root/Automation_Project/automation.sh" > /etc/cron.d/automation
        echo "new cron job created"
fi

exit 0
