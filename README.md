# Ubuntu-14-Installer

Version: 3.0.1

Author: MapFig

OS Tested: Ubuntu 14.04.2.x64 LTS (recommended) and Ubuntu 14.10-x64


#For use on fresh install Ubuntu only!!


<h1>Installation</h1>
<h3>Installer Requirements </h3>
<ul>
<li>Access to a working SMTP email account.  While you can configure this on the box you install petiole, the application is designed to authenticate email and links via an smtp email service. If you do not want email verification functionality or do not have access to an SMTP email account, see "Bypass Email Requirements" below.</li>
</ul>


<p>&nbsp;</p>
<h3>Ubuntu 14.x </h3>
<h4>The following is only for use on a <strong>clean installation</strong>.  </h4>

<p class="style7 style4">Get the installer from our secure CDN: 
<pre>[root@server ~]# wget https://cdn.acugis.com/petiole/v301/petiole-3.0.1-Ubuntu-14.0.4.sh</pre> </p>
<p><span class="style7 style4">Check the file integrity</span>:
<pre>[root@server ~]# md5sum petiole-3.0.1-Ubuntu-14.0.4.sh</pre>
<p><span class="style4">MD5 output should match <a href="https://cdn.acugis.com/petiole/v301/petiole-3.0.1-Ubuntu-14.0.4-md5.txt" target="_blank">https://cdn.acugis.com/petiole/v301/petiole-3.0.1-Ubuntu-14.0.4-md5.txt</a></span></p>

<p><span class="style7 style4">Make the file executable</span>:

<pre>[root@server ~]# chmod 755 petiole-3.0.1-Ubuntu-14.0.4.sh</pre></p>
<p><span class="style7 style4">Run the installer! </span>
<pre>[root@server ~]# ./petiole-3.0.1-Ubuntu-14.0.4.sh</pre></p>

<p>&nbsp;</p>
<p class="style2">The script takes a few minutes, be patient. You will be prompted for SMTP credentials (required) as well as domain/VHOST (can be changed later). If you do not have access to an email account see <a href="#EMAILBYPASS-DO">email section</a> below. </p>
<p class="style1">&nbsp;</p>
<p class="style2">A the end of installation your mapfig user password, map database name, stats database name, and password, and postgres password will be displayed as below as well as saved to an auth file (/root/studio-install.auth) on the file system.</p>
<p class="style1"><pre>INFO:
Virtual Host Configuration: /etc/apache2/sites-enabled/000-default.conf
Your studio database name is: djzioxdqokyxfc
Your studio stats database name is: djzioxdqokyxfc_stats
Your studio postgresql user password is: QnIkNVMIV0IwpmcEMqny73eFQ91XBLB6
Your studio os user password is: gLhr9aPcR_hz3xEJtLdfqf6o1-cx0OVJ
Your postgres superuser password is: J7UNZ0tnyQGHmYOC7yz-sEltkAfmvkxE
root@mapfig:/opt#</pre></p>
<p class="style1">&nbsp;</p>
<p class="style2">Navigate to your VM IP and follow the installation screens:</p>
<p class="style1">&nbsp;</p>
<p class="style2">Enter the db names and pgsql password from end of install script: </p>
<p class="style1"><img src="https://cdn.acugis.com/petiole/v301/petdocs/populated.jpg"></p></p>
<p class="style1">&nbsp;</p>
<p class="style2">Select Admin User Name, Password, and Email: </p>
<p class="style1"><img src="https://cdn.acugis.com/petiole/v301/petdocs/populated-indo.jpg"></p>
<p class="style1">&nbsp;</p>
<p class="style2"><span class="style5 style3">Check you email, click the verification link and log in:.</p>
<p class="style1">&nbsp;</p>
<img src="https://cdn.acugis.com/petiole/v301/petdocs/DONE.jpg"></p>

<p>&nbsp;</p>
<p>&nbsp;</p>
<h4>&nbsp;</h4>
<h4>Bypass Email Requirements</a></h4>
<p class="style2"><span class="style3">If you do not wish to use email functionality, or do not have access to an SMTP server</span>, connect as user mapfig or postgres to the postgresql database that was created by the script (djzioxdqokyxfc, in our example above) :</p>
<p class="style1">&nbsp;</p>
<p>
<pre>root@mapfig:/opt# su - mapfig
$ psql -d djzioxdqokyxfc -U mapfig
Password for user mapfig:
psql (9.4.4)
Type "help" for help.

dfwhlcivlwtnct=></pre>
</p>
<p class="style2">Run the update statement below,  where 'me@myemail.com' is the email you used during installation:
</p>
<p>
<pre>dfwhlcivlwtnct=> update users set activationkey = '' where email = 'david@acugis.com';</pre>
</p>

