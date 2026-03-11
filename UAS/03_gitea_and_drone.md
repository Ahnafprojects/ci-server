# Instalasi Gitea dan Drone CI menggunakan docker

## ⚙️ 1. Prasyarat Jaringan dan File Konfigurasi

### A. Jaringan Docker Kustom (Custom Network) 🌐

Layanan Gitea, Drone Server, dan Drone Runner harus berada dalam satu jaringan kustom. Hal ini penting untuk dua alasan:

1.  **Resolusi Nama:** Mereka dapat saling berkomunikasi menggunakan nama layanan (*service name*) mereka (misalnya, Drone Server dapat merujuk ke Gitea hanya sebagai `gitea`, bukan IP address yang berubah-ubah).
2.  **Isolasi:** Memisahkan *traffic* internal CI/CD dari *traffic* Docker yang lain.

**Konfigurasi di `docker-compose.yml` (Bagian `networks`):**

Kita akan mendefinisikan satu jaringan di akhir *file*:

```yaml
# ... Definisi services lainnya ...

networks:
  ci-network: # Nama jaringan kustom
    driver: bridge # Menggunakan driver bridge default Docker
```

Semua *service* (`gitea`, `drone-server`, `drone-runner`) harus secara eksplisit ditambahkan ke jaringan `ci-network` ini.

-----

### B. File `docker-compose.yml` (Konfigurasi Dasar) 📝

Berikut adalah struktur lengkap `docker-compose.yml` yang akan digunakan di dalam Vagrant VM Anda.

```yaml
version: '3.8'

services:
# ==================================
# 1. GITEA (GIT SERVER)
# ==================================
  gitea:
    image: gitea/gitea:latest
    container_name: gitea
    environment:
      # URL yang akan digunakan oleh Drone CI dan Webhook
      - GITEA__SERVER__ROOT_URL=http://[IP_VM]:3000/ 
      # Menonaktifkan pendaftaran (registrasi) publik setelah setup awal
      - GITEA__SERVER__DISABLE_REGISTRATION=true 
    volumes:
      - ./gitea:/data # Volume untuk menyimpan data persisten Gitea (database, repository)
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "3000:3000" # Port Web Gitea (Akses dari Host via VM IP)
      - "222:22"    # Port SSH untuk Git Clone/Push (Wajib diubah karena port 22 sudah dipakai oleh SSH VM)
    restart: always
    networks:
      - ci-network # Terhubung ke jaringan CI
    # Menggunakan database SQLite sederhana di volume data untuk lab
    command: sh -c "/usr/bin/gitea web" 

# ==================================
# 2. DRONE SERVER (CORE CI/CD)
# ==================================
  drone-server:
    image: drone/drone:latest
    container_name: drone-server
    environment:
      # RAHASIA: Kunci unik untuk komunikasi Server dan Runner (Wajib dibuat)
      - DRONE_RPC_SECRET=ini-adalah-kunci-rahasia-rpc 
      # URL akses publik Drone (digunakan Gitea untuk Webhook Redirect)
      - DRONE_SERVER_HOST=[IP_VM]:8000 
      - DRONE_SERVER_PROTO=http 

      # INTEGRASI GITEA (OAUTH Setup)
      - DRONE_GITEA_SERVER=http://gitea:3000 # Akses Gitea via service name
      - DRONE_GITEA_CLIENT_ID=
      - DRONE_GITEA_CLIENT_SECRET=
      - DRONE_GITEA_SKIP_VERIFY=true
      - DRONE_USER_CREATE=username:admin,admin:true # Membuat admin pertama
    volumes:
      - ./drone-server:/data # Volume database persisten Drone
    ports:
      - "8000:80" # Port Web Drone (Akses dari Host)
    restart: always
    networks:
      - ci-network

# ==================================
# 3. DRONE RUNNER (JOB EXECUTION)
# ==================================
  drone-runner:
    image: drone/drone-runner-docker:latest
    container_name: drone-runner
    environment:
      - DRONE_RPC_SECRET=ini-adalah-kunci-rahasia-rpc # Harus sama dengan Server
      - DRONE_RPC_HOST=drone-server:80 # Akses Server via service name
      - DRONE_RPC_PROTO=http
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock # Wajib: Untuk menjalankan job (container)
    restart: always
    networks:
      - ci-network

# ==================================
# DEFINISI JARINGAN
# ==================================
networks:
  ci-network:
    driver: bridge
```

-----

**Catatan :**

1.  **`[IP_VM]`:** Nilai ini harus diganti dengan **IP Address Vagrant VM Anda** yang dapat diakses dari *Host* (misalnya `192.168.56.10`).
2.  **`DRONE_RPC_SECRET`:** Nilai kunci rahasia ini **harus sama** di `drone-server` dan `drone-runner`.
3.  **SSH Gitea:** Port SSH di Gitea diubah dari `22` menjadi `222` karena Port 22 di dalam VM sudah digunakan oleh layanan SSH Vagrant.

-----

## 💾 2. Instalasi dan Konfigurasi Gitea (Git Server)

Materi ini fokus pada *deployment* Gitea menggunakan `docker-compose.yml` yang sudah disiapkan dan menyelesaikan konfigurasi dasarnya.

### A. Deployment Cepat 🚀

Langkah-langkah ini dijalankan di **Host Machine** (atau di dalam *terminal* VM Anda jika sudah *login*), dari direktori tempat *file* `docker-compose.yml` berada.

1.  **Meluncurkan Layanan:** Eksekusi Docker Compose untuk menjalankan *container* **Gitea**, **Drone Server**, dan **Drone Runner** di *background*.

    ```bash
    docker compose up -d
    ```

2.  **Verifikasi Status:** Pastikan *container* `gitea` berhasil *running* dan terhubung ke jaringan `ci-network`.

    ```bash
    docker ps | grep gitea
    ```

3.  **Akses Instalasi Awal:** Buka *browser* di Host Machine Anda dan akses Gitea melalui alamat yang dipetakan di *port mapping* (`3000:3000`).

    ```
    http://localhost:3000
    ```

    *(Jika Anda menggunakan VM, ganti `localhost` dengan IP VM Anda, misalnya `http://192.168.56.10:3000`)*

4.  **Konfigurasi Database & Admin (Web Setup):** Gitea akan meminta Anda mengisi pengaturan awal saat pertama kali diakses:

      * **Database Type:** Pilih **SQLite3** (karena sudah dikonfigurasi untuk menggunakan *volume*).
      * **Application General Settings:**
          * **Gitea Base URL:** Atur menjadi **URL yang dapat diakses dari luar** (misalnya `http://[IP_HOST/VM]:3000/`).
      * **Administrator Account Settings:** Buat akun Administrator pertama (misalnya Username: `admin`).
      * Klik **Install Gitea**.

-----

### B. Jaringan (Aksesibilitas) 🌐

Ini memastikan Gitea dapat berkomunikasi dengan Host Anda dan layanan Drone CI.

1.  **Akses dari Host (Web & SSH):**

      * **Web (HTTP):** Diizinkan melalui *port mapping* **`3000:3000`** di `docker-compose.yml`.
      * **SSH (Git):** Diizinkan melalui *port mapping* **`222:22`**. Ini memungkinkan *Host* Anda melakukan *clone* menggunakan SSH ke `ssh://git@localhost:222/admin/myrepo.git`.

2.  **Akses oleh Drone CI (Internal Container Network):**

      * **Tujuan:** Drone Server perlu *login* dan menerima *webhook* dari Gitea.
      * **Mekanisme:** Keduanya berada di jaringan kustom **`ci-network`**. Oleh karena itu, Drone CI dapat merujuk ke Gitea menggunakan **nama layanan** *default* Docker Compose: `http://gitea:3000`. Ini menjamin komunikasi internal yang stabil.

Setelah Gitea berjalan, kita siap untuk menginstal dan mengintegrasikan Drone CI.

-----

## 🚀 3. Instalasi dan Konfigurasi Drone CI (CI/CD Server)

Drone CI terdiri dari dua komponen utama: **Drone Server** (antarmuka web dan *orchestrator*) dan **Drone Runner** (mesin yang menjalankan *pipeline*). Keduanya berkomunikasi menggunakan kunci rahasia (*RPC Secret*) dan berjalan berdampingan di dalam jaringan Docker yang sama.

### A. Deployment Cepat Drone Server dan Runner

Karena Anda telah menjalankan `docker compose up -d` di langkah Gitea sebelumnya, *container* Drone sudah seharusnya berjalan.

1.  **Verifikasi Status:** Pastikan kedua komponen Drone sudah *running* dan terhubung ke `ci-network`.

    ```bash
    docker ps | grep drone
    ```

    *Output yang Diharapkan:* Akan terlihat *container* `drone-server` dan `drone-runner` dengan status `Up`.

2.  **Akses Web Drone:** Akses Drone Server dari *browser* Host Anda melalui *port mapping* **`8000:80`** yang sudah kita definisikan.

    ```
    http://[IP_HOST/VM]:8000
    ```

    *(Ganti `[IP_HOST/VM]` dengan `localhost` atau IP Vagrant Anda)*

    Saat diakses, Drone akan segera mengarahkan Anda ke halaman *login* Gitea, yang membuktikan konfigurasi lingkungan telah berhasil.

-----

### B. Konfigurasi Lingkungan Kritis ⚙️

Instalasi Drone CI sangat bergantung pada variabel lingkungan (*Environment Variables*) di `docker-compose.yml` untuk mengetahui siapa dirinya, di mana *Git Server* (Gitea) berada, dan bagaimana ia berbicara dengan *Runner*.

Berikut adalah penjelasan fungsi variabel lingkungan utama yang sudah kita atur di **Drone Server**:

| Variabel Lingkungan | Nilai yang Ditetapkan | Fungsi Kritis |
| :--- | :--- | :--- |
| **`DRONE_SERVER_HOST`** | `[IP_VM]:8000` | **URL Publik Drone.** Wajib dikenali oleh Gitea untuk *redirect* *login* (OAuth) dan menerima *webhook*. |
| **`DRONE_SERVER_PROTO`** | `http` | Protokol yang digunakan *Host* untuk mengakses Drone Server. |
| **`DRONE_RPC_SECRET`** | `ini-adalah-kunci-rahasia-rpc` | **Kunci Rahasia Utama.** Digunakan untuk otentikasi komunikasi antara **Drone Server** dan **Drone Runner** yang terpisah. Kunci ini *harus* identik di kedua *container*. |
| **`DRONE_GITEA_SERVER`** | `http://gitea:3000` | **Koneksi Internal ke Gitea.** Drone Server menggunakan nama layanan Docker Compose (`gitea`) untuk mengakses API Gitea di Port 3000. |
| **`DRONE_GITEA_CLIENT_ID`** | (Kosong, akan diisi) | **Kunci OAuth.** Akan diisi pada langkah berikutnya setelah kita mendaftarkan Drone di Gitea. |
| **`DRONE_GITEA_CLIENT_SECRET`** | (Kosong, akan diisi) | **Rahasia OAuth.** Akan diisi pada langkah berikutnya. |
| **`DRONE_USER_CREATE`** | `username:admin,admin:true` | **Bootstrap Admin.** Secara otomatis membuat pengguna `admin` Drone dan memberikan hak administrator saat pertama kali dijalankan. |

Dan berikut adalah variabel lingkungan utama di **Drone Runner**:

| Variabel Lingkungan | Nilai yang Ditetapkan | Fungsi Kritis |
| :--- | :--- | :--- |
| **`DRONE_RPC_HOST`** | `drone-server:80` | **Akses ke Server.** Runner menggunakan nama layanan Docker Compose (`drone-server`) untuk meminta *job* baru dari Server. |
| **`DRONE_RPC_SECRET`** | `ini-adalah-kunci-rahasia-rpc` | **Kunci Rahasia Komunikasi.** Memastikan Runner hanya menerima perintah dari Server yang sah. |
| **Volume `/var/run/docker.sock`** | (Mapping) | **Wajib.** Memberikan akses kepada Runner ke *Docker Daemon* Host. Ini memungkinkan Runner menjalankan *container* untuk *build* *pipeline*. |

Pada tahap ini, *backend* CI/CD Anda sudah berjalan. Langkah selanjutnya adalah menghubungkan keduanya secara resmi menggunakan **OAuth**.

-----

## 🔗 4. Integrasi Gitea dan Drone CI

Drone CI harus diizinkan untuk *login* ke Gitea atas nama pengguna Anda dan menyinkronkan *repository*. Izin ini diberikan melalui mekanisme **OAuth 2.0**.

1.  **Akses Gitea:** *Login* ke Gitea sebagai administrator (`http://[IP_HOST/VM]:3000`).

2.  **Navigasi:** Masuk ke **Settings (Pengaturan)** admin global, lalu pilih **Applications (Aplikasi)**, dan klik **Manage OAuth2 Applications (Kelola Aplikasi OAuth2)**.

3.  **Daftarkan Aplikasi Baru:** Klik **Add Application (Tambah Aplikasi)**.

      * **Application Name:** `Drone CI Server`
      * **Redirect URL:** Masukkan URL *redirect* Drone CI. Ini **Wajib** mengikuti pola:
        ```
        http://[IP_HOST/VM]:8000/login
        ```
        *(Ganti `[IP_HOST/VM]` sesuai alamat yang Anda gunakan untuk mengakses Drone CI.)*

4.  **Simpan Kunci:** Setelah aplikasi dibuat, Gitea akan menampilkan dua kunci penting:

      * **Client ID**
      * **Client Secret**

5.  **Perbarui `docker-compose.yml`:** Segera masukkan kedua kunci ini ke dalam variabel lingkungan `drone-server` di *file* `docker-compose.yml` Anda (Layanan `drone-server`):

    ```yaml
        # ... di bawah drone-server
        environment:
          # ...
          - DRONE_GITEA_CLIENT_ID=<SALIN_CLIENT_ID_DI_SINI>
          - DRONE_GITEA_CLIENT_SECRET=<SALIN_CLIENT_SECRET_DI_SINI>
          # ...
    ```

6.  **Restart Drone Server:** Setelah `docker-compose.yml` diperbarui, *restart* layanan Drone Server agar kunci baru termuat.

    ```bash
    docker compose restart drone-server
    ```

-----

### B. Sinkronisasi Repository (Login Pertama) ✨

Langkah ini menguji integrasi OAuth yang baru saja Anda atur.

1.  **Akses Drone CI:** Buka Drone CI di *browser* Anda (`http://[IP_HOST/VM]:8000`).
2.  **Redirect Login:** Drone akan mengarahkan Anda ke halaman *Authorization* Gitea.
3.  **Otorisasi:** Klik **Authorize (Otorisasi)** di Gitea.
4.  **Sinkronisasi:** Setelah otorisasi, Drone CI akan secara otomatis:
      * Membuat akun pengguna baru untuk Anda (berdasarkan *username* Gitea).
      * Melakukan **Sinkronisasi Repository**, menampilkan semua *repository* yang Anda miliki di Gitea.

-----

### C. Aktivasi Webhook dan Pipeline Awal 🎣

Setelah *repository* terlihat di *interface* Drone CI, Anda perlu mengaktifkan *pipeline* untuk *repository* tersebut.

1.  **Pilih dan Aktifkan Repository:** Di dasbor Drone CI, pilih *repository* yang ingin Anda gunakan (misalnya, `projek1/myapp`). Klik tombol **Activate (Aktifkan)**.
2.  **Pendaftaran Webhook Otomatis:** Saat diaktifkan, Drone CI akan melakukan dua hal di Gitea secara otomatis:
      * Menambahkan kunci publik SSH Drone CI sebagai *Deploy Key* di *repository* Gitea.
      * Mendaftarkan **Webhook** baru di pengaturan Gitea, dengan URL yang menunjuk ke Drone Server (`http://[IP_HOST/VM]:8000/hook?secret=...`).
3.  **Verifikasi Webhook (Opsional):** Anda dapat memverifikasi di pengaturan *repository* Gitea (menu **Webhooks**) bahwa *webhook* Drone sudah terdaftar dan aktif.

---

# installa menggunakan vagrant

## ⚙️ 1. Prasyarat & Penyiapan Lingkungan Vagrant
---

> **⚠️ Catatan Kritis Mengenai Jaringan**
>
> **Sesuaikan *subnet* Docker Compose (misalnya untuk *ci-network* dan *harbor-network*) dengan *subnet* Kubernetes Cluster Anda (misalnya 10.0.0.0/24).**
>
> Hal ini untuk mencegah konflik alamat IP saat mencoba menghubungkan *container* di Host/VM (Harbor/Gitea/Drone) dengan *Pods* yang berjalan di dalam *cluster* Kubernetes.

---
### A. Kebutuhan Host (Host Machine Requirements)

Agar *Host Machine* (komputer mahasiswa) dapat menjalankan lingkungan VM dengan baik, dua *tool* utama wajib terinstal:

1.  **Vagrant:** *Tool* untuk mendefinisikan dan mengotomatisasi konfigurasi VM.
2.  **VirtualBox atau Hypervisor Lain:** Perangkat lunak virtualisasi yang akan menjalankan VM (misalnya, VirtualBox direkomendasikan karena paling umum digunakan dan stabil dengan Vagrant).

### B. Konfigurasi `Vagrantfile` (Pusat Kendali VM)

`Vagrantfile` adalah *blueprint* yang mendefinisikan *box*, *resource*, jaringan, dan skrip instalasi (*provisioning*) yang harus dijalankan di dalam VM.

Berikut adalah contoh `Vagrantfile` yang optimal untuk lingkungan Gitea dan Drone CI:

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # 1. Menentukan OS Dasar (Box)
  config.vm.box = "ubuntu/focal64"
  config.vm.hostname = "ci-devops"
  
  # 2. Pengaturan Jaringan Kritis (Akses Gitea/Drone dari Host)
  config.vm.network "private_network", ip: "192.168.56.10"
  # Catatan: IP 192.168.56.10 adalah alamat VM yang akan digunakan di browser Host.
  
  # 3. Alokasi Resource VM
  config.vm.provider "virtualbox" do |vb|
    vb.name = "CI-DevOps-Stack"
    # Alokasi RAM minimal 4GB (Wajib untuk Gitea + Drone + Docker)
    vb.memory = 4096 
    # Alokasi 2 CPU Core
    vb.cpus = 2 
    vb.gui = false
  end
  
  # 4. Provisioning (Instalasi Otomatis di Dalam VM)
  config.vm.provision "shell", path: "install.sh"
end
```

### C. Skrip Provisioning: `install.sh` (Instalasi Docker)

Skrip ini adalah bagian paling kritis. Skrip ini dijalankan hanya sekali saat `vagrant up` pertama kali, dan bertanggung jawab menginstal semua prasyarat yang dibutuhkan untuk menjalankan Docker Compose di dalam VM.

Buat *file* terpisah bernama `install.sh` di direktori yang sama dengan `Vagrantfile`.

```bash
#!/bin/bash

echo "--- Memulai Provisioning: Instalasi Docker dan Dependencies ---"

# Update sistem
sudo apt update -y
sudo apt upgrade -y

# 1. Instalasi Docker
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io

# 2. Instalasi Docker Compose
# Mendapatkan versi stabil terbaru Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 3. Pengaturan Izin Pengguna
# Menambahkan pengguna 'vagrant' ke grup 'docker' agar tidak perlu menggunakan sudo
sudo usermod -aG docker vagrant

echo "--- Provisioning Selesai ---"
echo "Silakan reboot VM dengan 'vagrant reload' agar perubahan grup berlaku."
```

### D. Prosedur Deployment

Mahasiswa akan menjalankan dua perintah di *Host Machine* mereka untuk mengaktifkan lingkungan:

1.  **Deployment VM:** `vagrant up`
2.  **Akses VM:** `vagrant ssh`

Setelah berada di dalam VM, mereka dapat melanjutkan ke langkah berikutnya, yaitu menjalankan `docker compose up -d` menggunakan IP **`192.168.56.10`** sebagai *hostname* utamanya.


## 📝 2. File `docker-compose.yml` di Dalam VM

*File* ini akan ditempatkan di dalam VM (misalnya di `/home/vagrant/devops-ci/`) dan dijalankan menggunakan `docker compose up -d`.

### A. Struktur File dan Definisi Layanan

```yaml
version: '3.8'

services:
# ==================================
# 1. GITEA (GIT SERVER)
# ==================================
  gitea:
    image: gitea/gitea:latest
    container_name: gitea
    environment:
      # URL PUBLIK Gitea (menggunakan IP Vagrant VM: 192.168.56.10)
      - GITEA__SERVER__ROOT_URL=http://192.168.56.10:3000/ 
      - GITEA__SERVER__DISABLE_REGISTRATION=true 
    volumes:
      - ./gitea:/data # Volume data persisten untuk repository dan database SQLite
    ports:
      - "3000:3000" # Port Web Gitea
      - "222:22"    # Port SSH Gitea (di-map ke 222 di VM)
    restart: always
    networks:
      - ci-network 

# ==================================
# 2. DRONE SERVER (CORE CI/CD)
# ==================================
  drone-server:
    image: drone/drone:latest
    container_name: drone-server
    environment:
      # DRONE SERVER HOST: URL publik Drone (digunakan Gitea untuk Webhook)
      - DRONE_SERVER_HOST=192.168.56.10:8000 
      - DRONE_SERVER_PROTO=http 

      # KONFIGURASI DRONE CORE
      - DRONE_RPC_SECRET=kunci-rahasia-projek-drone-2025 # <-- Wajib sama dengan Runner!
      - DRONE_USER_CREATE=username:admin,admin:true 

      # KONFIGURASI INTEGRASI GITEA (OAuth akan diisi nanti)
      - DRONE_GITEA_SERVER=http://gitea:3000 # Akses Gitea via service name di ci-network
      - DRONE_GITEA_CLIENT_ID=
      - DRONE_GITEA_CLIENT_SECRET=
    volumes:
      - ./drone-server:/data # Volume database persisten Drone
    ports:
      - "8000:80" # Port Web Drone
    restart: always
    networks:
      - ci-network

# ==================================
# 3. DRONE RUNNER (JOB EXECUTION)
# ==================================
  drone-runner:
    image: drone/drone-runner-docker:latest
    container_name: drone-runner
    environment:
      - DRONE_RPC_SECRET=kunci-rahasia-projek-drone-2025 # <-- Harus sama dengan Server!
      - DRONE_RPC_HOST=drone-server:80 # Akses Server via service name
      - DRONE_RPC_PROTO=http
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock # Wajib: Untuk menjalankan job di Host VM
    restart: always
    networks:
      - ci-network

# ==================================
# DEFINISI JARINGAN
# ==================================
networks:
  ci-network:
    driver: bridge
```

-----

### B. Konfigurasi Kritis (Gitea)

  * **Persistensi Data:** Dengan mendefinisikan `volumes: - ./gitea:/data`, semua *repository* dan pengaturan Gitea (termasuk *database* SQLite) akan disimpan secara permanen di direktori `./gitea` di dalam VM.
  * **URL Akses:** `GITEA__SERVER__ROOT_URL=http://192.168.56.10:3000/` memastikan bahwa Gitea memberikan URL yang benar kepada Drone CI untuk *webhook*. **`192.168.56.10`** adalah IP Vagrant VM yang diakses oleh *Host*.
  * **SSH Port:** Port `222:22` mencegah konflik dengan layanan SSH utama VM dan memungkinkan `git clone` via SSH dari *Host* ke VM.

### C. Konfigurasi Kritis (Drone CI)

  * **Koneksi Internal (Drone Server ke Gitea):** `DRONE_GITEA_SERVER=http://gitea:3000`. Server menggunakan nama layanan `gitea` di *custom network* `ci-network` untuk terhubung, yang jauh lebih stabil daripada menggunakan IP *container*.
  * **Kunci Rahasia RPC:** Variabel **`DRONE_RPC_SECRET`** yang identik di kedua *service* (`drone-server` dan `drone-runner`) adalah kunci otentikasi. Tanpa kunci ini, *Runner* tidak dapat menerima instruksi dari *Server*.
  * **Runner Access:** Volume **`/var/run/docker.sock:/var/run/docker.sock`** sangat penting. Ini memberikan *Runner* izin untuk mengakses *Docker Daemon* VM sehingga *Runner* dapat membuat *container* baru (tempat *pipeline* berjalan).

*File* ini kini siap untuk di-*deploy* di dalam Vagrant VM. Selanjutnya, kita akan membahas *setup* awal Gitea.

Tentu, Bapak Arif. Setelah penyiapan `Vagrantfile` dan `docker-compose.yml` selesai, langkah berikutnya adalah eksekusi *deployment* dan konfigurasi dasar **Gitea** di dalam VM.

-----

## 💾 3. Deployment dan Konfigurasi Awal Gitea

### A. Deployment Lingkungan CI/CD 🚀

Instruksi ini mengasumsikan Anda berada di direktori **Host** yang sama dengan `Vagrantfile` dan `docker-compose.yml`.

1.  **Luncurkan dan Provisioning VM:**
      * Perintah ini akan menjalankan VM, menginstal Docker dan Docker Compose (menggunakan skrip `install.sh`), dan menetapkan IP **`192.168.56.10`**.
    <!-- end list -->
    ```bash
    vagrant up
    ```
2.  **Akses ke VM:**
      * Masuk ke *terminal* di dalam VM.
    <!-- end list -->
    ```bash
    vagrant ssh
    ```
3.  **Jalankan Docker Compose:**
      * Setelah masuk ke dalam VM, navigasi ke direktori tempat `docker-compose.yml` berada, lalu jalankan semua layanan (Gitea, Drone Server, Drone Runner).
    <!-- end list -->
    ```bash
    docker compose up -d
    ```
4.  **Verifikasi Layanan:**
      * Pastikan *container* `gitea` sudah *running*.
    <!-- end list -->
    ```bash
    docker ps | grep gitea
    ```

-----

### B. Setup Awal Gitea (Web Interface) 🌐

Akses Gitea dari **Host Machine** Anda untuk menyelesaikan instalasi database dan administrator.

1.  **Akses Browser:** Buka alamat Gitea di *Host* Anda:
    ```
    http://192.168.56.10:3000
    ```
2.  **Konfigurasi Database:**
      * Biarkan **Database Type** sebagai **SQLite3** (karena sudah dikonfigurasi menggunakan *volume*).
3.  **Pengaturan Aplikasi (Wajib):**
      * **Gitea Base URL:** Atur ke **`http://192.168.56.10:3000/`** (Kritis untuk *webhook* Drone CI).
      * **Server SSH Port:** Biarkan **`22`** (Ini adalah port SSH **di dalam *container***).
      * **HTTP Port:** Biarkan **`3000`**.
4.  **Akun Administrator:**
      * Buat akun administrator (misalnya **Username:** `admin`, **Password:** *passwordku*). Ini adalah akun yang akan digunakan untuk *login* ke Drone CI nanti.
5.  **Finalisasi:** Klik **Install Gitea**.

-----

### C. Pengaturan SSH (Git Cloning) 🔑

Meskipun Gitea berjalan di Port 22 di dalam *container*, *Host* mengaksesnya melalui Port **222** (seperti yang didefinisikan di `docker-compose.yml`: `222:22`). Pengaturan ini penting untuk *clone* via SSH.

1.  **Buat Repository Uji:** *Login* ke Gitea dan buat *repository* baru (misalnya, `projek1-app`).
2.  **Verifikasi URL Clone:** Di halaman *repository* Gitea, ketika memilih opsi SSH, Anda akan melihat URL yang ditampilkan oleh Gitea (Contoh: `git@192.168.56.10:projek1-app.git`).
3.  **Koreksi Klien Host:** Saat melakukan *clone* dari **Host**, mahasiswa **harus** menambahkan port `222` secara manual ke perintah *clone* atau mengkonfigurasi SSH *config* di Host:
    ```bash
    # Perintah clone yang benar dari HOST
    git clone ssh://git@192.168.56.10:222/admin/projek1-app.git 
    ```
    *Catatan:* Jika port 222 tidak ditambahkan, *Host* akan mencoba koneksi ke port SSH VM utama (22), yang tidak akan mencapai Gitea *container*.

Dengan selesainya langkah ini, Git Server (Gitea) Anda berfungsi penuh dan siap diintegrasikan dengan Drone CI.


## 🔗 4. Integrasi Gitea dan Drone CI (OAuth)

Langkah-langkah ini dilakukan setelah Gitea dan Drone CI sudah berjalan di dalam Vagrant VM (`192.168.56.10`).

### A. Mendaftarkan Aplikasi OAuth di Gitea 🔑

Proses ini dilakukan di *web interface* Gitea untuk memberi tahu Gitea bahwa Drone CI adalah aplikasi eksternal yang sah.

1.  **Login ke Gitea:** *Login* ke Gitea melalui `http://192.168.56.10:3000` menggunakan akun administrator (`admin`).
2.  **Navigasi ke OAuth:** Buka **Settings (Pengaturan)** global, lalu pilih **Applications (Aplikasi)**, dan klik **Manage OAuth2 Applications (Kelola Aplikasi OAuth2)**.
3.  **Tambahkan Aplikasi Baru:** Klik **Add Application (Tambah Aplikasi)** dan isi detail berikut:
      * **Application Name:** `Drone CI Server`
      * **Redirect URL:** Ini harus menjadi URL yang dapat diakses Drone CI dari *browser* Anda:
        ```
        http://192.168.56.10:8000/login
        ```
      * **Pilih Jenis Aplikasi:** Pilih **Confidential (Rahasia)**.
4.  **Simpan Kunci:** Setelah aplikasi dibuat, Gitea akan menampilkan dua kunci yang sangat penting:
      * **Client ID**
      * **Client Secret**

### B. Menghubungkan Drone (Injeksi Kunci) 🔌

Kunci yang didapat dari Gitea harus segera dimasukkan ke konfigurasi Drone Server agar koneksi berfungsi.

1.  **Edit `docker-compose.yml`:** Buka *file* `docker-compose.yml` yang ada di dalam Vagrant VM dan masukkan **Client ID** serta **Client Secret** ke variabel lingkungan di *service* `drone-server`.

    ```yaml
    # ... di bawah drone-server
    environment:
      # ...
      - DRONE_GITEA_CLIENT_ID=<SALIN_CLIENT_ID_DARI_GITEA>
      - DRONE_GITEA_CLIENT_SECRET=<SALIN_CLIENT_SECRET_DARI_GITEA>
      # ...
    ```

2.  **Restart Drone Server:** Agar variabel lingkungan yang baru diterapkan, *container* Drone Server harus di-*restart* (tidak perlu Drone Runner).

    ```bash
    # Perintah dijalankan di terminal Vagrant VM
    docker compose restart drone-server
    ```

### C. Uji Koneksi dan Sinkronisasi 🤝

Langkah ini memverifikasi bahwa Drone CI dan Gitea sekarang terhubung dan dapat saling berkomunikasi.

1.  **Akses Drone CI:** Buka *browser* di *Host* Anda: `http://192.168.56.10:8000`.
2.  **Proses OAuth:** Drone Server akan mendeteksi bahwa kunci OAuth sudah terpasang. Ia akan segera mengarahkan Anda ke halaman *Authorization* Gitea.
3.  **Otorisasi:** Klik tombol **Authorize (Otorisasi)** di Gitea. Ini mengizinkan Drone CI untuk bertindak atas nama akun Gitea Anda.
4.  **Sinkronisasi Berhasil:** Anda akan diarahkan kembali ke *dashboard* Drone CI, yang sekarang menampilkan daftar semua *repository* yang Anda miliki di Gitea. Ini menandakan integrasi OAuth berhasil sepenuhnya.

Setelah terintegrasi, *user* di Drone CI secara otomatis di-*manage* berdasarkan *user* yang ada di Gitea. Kini Anda dapat melanjutkan ke aktivasi *repository* untuk mulai menulis *pipeline* pertama Anda.


