
# Aurora Rails 5 v2 Web Server
# 極光 Rails 5 專屬伺服器 安裝包

* Version: 1.0.0 ( 20180324 )

# 系統要求

* Ubuntu 16.04 作業系統
* 需要有 root 的權限的帳號，並且可以使用 sh 或 bash
* (選項) SSD VPS

# 安裝項目

* 系統更新、必要設定、必備套件、node-js、Image Magick
* 建立一組給應用程式用的部署帳號 / 預設名為 apps
* 建立 Git Repo Deployment Key 與 建立無需密碼即可登入的機制
* Ruby 2.5.0 程式環境 / with rbenv
* Rails 5.1 Web Framework 與 rest-client、mailgun、backup、whenever 套件組
* Nginx Extras 與 Passenger Server
* 安裝 MariaDB 10.2 資料庫系統
* 基本的 SSH 安全設定，但不含 iptable 或 ufw 防火牆設定，請自行設定
* 安裝輔助工具在部署帳號環境上

# 注意事項

1. 所有的上線環境安裝完畢後，最好使用防火牆將 ssh 的連線只開放特定的 ip 使用
2. 腳本不會更動 root 帳號的密碼
3. 針對 VPS 或虛擬環境進行網路參數的優化
4. 安裝完畢後，SSH 連接 port 預設會從 22 改為 56888
5. 本腳本可以跑在 虛擬 VPS 業者 提供的 Stack Script 下

# 安裝指令

1. 第一次使用，您需要透過 root 帳號 或 擁有不需要輸入 sudo 的帳號來進行放置部署腳本
2. 使用第 1. 點提到的帳號進行登入
3. 開啟 sh 或 bash 來執行以下片段

```sh

# 需要透過 git 複製腳本資料下來到新機器上
rm -rfv /tmp/aurora-rails-5-v2-web-server
sudo apt-get install -y git
git clone https://github.com/guanting112/aurora-rails-5-v2-web-server.git --branch master --single-branch /tmp/aurora-rails-5-v2-web-server

# 0-machine-setting.sh 是整套腳本的基本設定，可以讓你設定 git repo、ssh key、ssh port、部署帳號的名稱、密碼等等
# 您可以修改它 或 自行上傳一份自行製作的版本來複寫掉這個檔案
cat /tmp/aurora-rails-5-v2-web-server/0-machine-setting.sh

# or

vi /tmp/aurora-rails-5-v2-web-server/0-machine-setting.sh

# 當準備上述指令執行完成後，你需要執行以下片段，進行為安裝環境初始化
. /tmp/aurora-rails-5-v2-web-server/0-init-deploy.sh

# 部署帳號預設名稱為 apps，這組帳號將會成為您日後部署 rails 時專用的 user

# 完整的腳本資料會放在 aurora-rails-5-v2-web-server 目錄下
ls /home/apps/aurora-rails-5-v2-web-server

# 當執行完畢後，你會在畫面上看到網站程式專用的部署帳號的密碼
# 看不到也可以用 .stickie 來顯示
cat /home/apps/.stickie

```

# 接著，登入 程式部署專用帳號

如果你有用 SSH_AUTHORIZED_KEYS 來建立無密碼登入，可以直接在終端機上 ssh apps@伺服器IP 來登入

```
ssh apps@10.10.10.101
# or 
ssh apps@10.10.10.101 -i PRIVATE_KEY
```

```bash

# 部署帳號的家目錄下，有一組 .stickie 檔案
# 該檔案記錄 您的帳號密碼相關資料，安裝完成後，日後不需要可以刪除
cat /home/apps/.stickie

# 執行 Aurora Rails 5 System Environment 主腳本
. ~/aurora-rails-5-v2-web-server/1-setup.sh

```

# 等待腳本執行完畢，若出現以下畫面，則表示成功完成安裝

1. 腳本有測試到資料庫連線，您在上述圖中看到 test connection ok 的訊息，表示 MySQL 連線是正常的
2. 伺服器安裝完畢後，您可以試著「重開伺服器」 或「重新登入」來確定環境是否載入成功
3. 您在此階段可以開始建立你的 Rails 的專案建立 或 Capistrano 的設定
4. 輸入 tips 指令來查看有什麼新指令可以使用

```
tips
```

# 其他

# LICENSE

本專案原始碼皆採 GNU GENERAL PUBLIC LICENSE 授權 ( 詳見 LICENSE 檔案 )

## 安裝完成後的輔助指令

```bash
update_sudo     # 只要 .stickie 在，您可以用 update_sudo 來代替 sudo -v 
setting_nginx   # 設定 nginx.conf
restart_nginx   # 重開 nginx
reload_nginx    # 不停機，重新載入 nginx.conf 設定
start_nginx     # 開啟 nginx
stop_nginx      # 停止 nginx
reset_nginx_log # 重置 nginx log 紀錄的 file pointer
test_nginx      # 測試 nginx 腳本是否正確
```

## create_rails_website_in_nginx 指令說明

當安裝完畢後，您可以使用此指令，建立一個 nginx 與 rails 互相連結的設定檔案在系統上
Rails 專案一定要放在家目錄內（例如：/home/apps）避免對應失敗
create_rails_website_in_nginx [專案名稱] [網域名稱] [public 資料夾位置]

```
# 假設我的 Rails 程式在家目錄，名稱是 news_app
# 網址是 news.example.com，指令會預設 public 位置
create_rails_website_in_nginx news_app news.example.com 

# 同上，但是 如果用 capistrano 部署，你可能要指定一個不一樣的 public 位置
create_rails_website_in_nginx news_app news.example.com current/public

# 建立完後，輸入 restart_nginx 重開伺服器
restart_nginx

# 或 reload
reload_nginx

# 基本上這樣就可以連線到你特定的 Rails App
curl -I "http://news.example.com/pages/home"

# 為了避免伺服器多個 Rails App 執行有問題 或 有人用其他網域來連線這個伺服器
# 瀏覽者是無法用 IP 直接存取伺服器上的網頁的
# 會得到一個 HTTP 400 (Bad Request)
curl -I "http://伺服器IP/pages/home"
```
