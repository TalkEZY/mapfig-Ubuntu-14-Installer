# Ubuntu-14-Installer

Version: 2.0.1

Author: MapFig

OS Tested: Ubuntu 14.04.2.x64 LTS (recommended) and Ubuntu 14.10-x64


#For use on fresh install Ubuntu only!!


<h1>Installation</h1>
<h3>System Requirements </h3>
<ul>
<li>Any Linux OS x64 </li>
<li>PHP 5.x</li>
<li>PostgreSQL 9.x</li>
<li>SuPHP or mod_ruid2</li>
<li>Postfix</li>
<li>GDAL>=1.8</li>
<li>Apache HTTP Server</li>
<li>Accessing to a working SMTP email account.  While you can configure this on the box you install MapFig Studio, the application is designed to authenticate email and links via an smtp email service. If you do not want email verification functionality or do not have access to an SMTP email account, see "Bypass Email Requirements" below.</li>

<li>The above components have been tested, lower or other versions may work. </li>
</ul>


<p>&nbsp;</p>
<h3>Ubuntu 14.x </h3>
<h4>The following is only for use on a <strong>clean installation</strong>.  </h4>

<p class="style7 style4">Get the installer from our secure CDN: 
<pre>[root@server ~]# wget https://cdn.mapfig.com/script-installers-v2/ubuntu-14-v2/mapfig-ubuntu-14-x64-v-2.0.1.sh</pre> </p>
<p><span class="style7 style4">Check the file integrity</span>:
<pre>[root@server ~]# md5sum mapfig-ubuntu-14-x64-v-2.0.1.sh</pre>
<p><span class="style4">MD5 output should match <a href="https://cdn.mapfig.com/script-installers-v2/ubuntu-14-v2/mapfig-ubuntu-14-x64-v-2.0.1-md5.txt" target="_blank">https://cdn.mapfig.com/script-installers-v2/ubuntu-14-v2/mapfig-ubuntu-14-x64-v-2.0.1-md5.txt</a></span></p>

<p><span class="style7 style4">Make the file executable</span>:

<pre>[root@server ~]# chmod 755 mapfig-ubuntu-14-x64-v-2.0.1.sh</pre></p>
<p><span class="style7 style4">Run the installer! </span>
<pre>[root@server ~]# ./mapfig-ubuntu-14-x64-v-2.0.1.sh</pre></p>

<p>&nbsp;</p>
<p class="style2">The script takes a few minutes, be patient. You will be prompted for SMTP credentials (required) as well as domain/VHOST (optional). If you do not have access to an email account see <a href="#EMAILBYPASS-DO">email section</a> below. </p>
<p class="style1">&nbsp;</p>
<p class="style2">A the end of installation your mapfig user password, database name, database password, and postgres password will be displayed as below as well as saved to an auth file (/root/mapfig-install.auth) on the file system.</p>
<p class="style1"><pre>INFO:
Virtual Host Configuration: /etc/apache2/sites-enabled/000-default.conf
Your mapfig postgresql database name is: dfwhlcivlwtnct
Your mapfig postgresql user password is: 5xvCmIVbhnY-XPK4vsEAAKlk56yuZtO5
Your mapfig os user password is: 64Hr8jUKSUTLyhgFxj4TK-hPIHH2p-ZT
Your postgres superuser password is: rEc-A3VX1M0s-WmsteT6CDDaiKgmrOjL
Password are saved in /root/mapfig-install.auth
root@mapfig:/opt#</pre></p>
<p class="style1">&nbsp;</p>
<p class="style2">Navigate to your VM IP and follow the installation screens:</p>
<p class="style1">&nbsp;</p>
<p class="style2">Red arrows below is mapfig db name and pgsql password from end of install script: </p>
<p class="style1"><img src="http://mapfig.org/images/do/InstallScreen.jpg"></p></p>
<p class="style1">&nbsp;</p>
<p class="style2">Select Admin User Name, Password, and Email: </p>
<p class="style1"><img src="http://mapfig.org/images/do/install-screen-3.jpg"></p>
<p class="style1">&nbsp;</p>
<p class="style2"><span class="style5 style3">If verifcation email does work</span>, follow steps below to  re-run mail configuration. You can re-run this as many times as you wish to set/change/update mail settings.</p>
<p class="style1">&nbsp;</p>
<p>
<pre>[root@server ~]# wget https://cdn.mapfig.com/script-installers-v2/ubuntu-14-v2/mapfig-mail-config-v2.0.1.sh</pre> </p>
<p><pre>[root@server ~]# chmod 755 mapfig-mail-config-v2.0.1.sh</pre></p>
<p><pre>[root@server ~]# ./mapfig-mail-config-v2.0.1.sh</pre></p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p class="style2"><span class="style5"><span class="style3">If you want to point a sub domain</span> <span class="style3">(e.g. maps.mydomain.com) and did not do so during the install</span></span>, follow steps below to  re-run vhost configuration. You can re-run this as many times as you wish to set/change/update mail settings.</p>
<p class="style1">&nbsp;</p>
<p>
<pre>[root@server ~]# wget https://cdn.mapfig.com/script-installers-v2/ubuntu-14-v2/mapfig-ubuntu-vhost-config-v2.0.1.sh</pre>
</p>
<p><pre>[root@server ~]# chmod 755 mapfig-ubuntu-vhost-config-v2.0.1.sh</pre></p>
<pre>[root@server ~]# ./mapfig-ubuntu-vhost-config-v2.0.1.sh</pre>
<h4>&nbsp;</h4>
<h4>Bypass Email Requirements</a></h4>
<p class="style2"><span class="style3">If you do not wish to use email functionality, or do not have access to an SMTP server</span>, connect as user mapfig to the postgresql database that was created by the script (dfwhlcivlwtnct, in our example above) :</p>
<p class="style1">&nbsp;</p>
<p>
<pre>root@mapfig:/opt# su - mapfig
$ psql -d dfwhlcivlwtnct -U mapfig
Password for user mapfig:
psql (9.4.4)
Type "help" for help.

dfwhlcivlwtnct=></pre>
</p>
<p class="style2">Run the update statement below,  where 'me@myemail.com' is the email you used during installation:
</p>
<p>
<pre>dfwhlcivlwtnct=> update users set activationkey = '' where email = 'me@myemail.com';</pre>
</p>

