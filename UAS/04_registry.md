# Image Registry (Penyimpanan dan Distribusi Artefak CI/CD)

## 🎯 1. Konsep Dasar dan Kebutuhan Registry

### A. Definisi Image Registry

**Image Registry** adalah sistem penyimpanan terpusat yang didedikasikan untuk menyimpan, mengelola, dan mendistribusikan *Docker Images* (atau *container images* lainnya, seperti OCI Images).

* **Analogi:** Jika Git adalah perpustakaan tempat menyimpan **blueprint** atau **resep** (kode sumber), maka *Registry* adalah **gudang** tempat menyimpan **produk jadi** (artefak *container* siap pakai).
* **Contoh:**
    * **Public Registry:** **Docker Hub** (gudang *image* publik terbesar).
    * **Private Registry:** **Harbor** (yang akan kita gunakan), Amazon ECR, Google Artifact Registry.

### B. Memastikan Terminologi yang Tepat

Dalam konteks *container*, tiga istilah ini sering digunakan, namun memiliki arti yang berbeda dan harus dipahami dengan benar:

| Istilah | Definisi | Analogi |
| :--- | :--- | :--- |
| **Image** | *File* statis, *read-only*, yang berisi semua yang dibutuhkan aplikasi untuk berjalan (kode, *runtime*, *library*, *filesystem*). | **Produk Jadi** (misalnya, CD perangkat lunak yang sudah diburning). |
| **Repository** | Kumpulan *Images* yang terkait dan memiliki nama yang sama, biasanya dibedakan berdasarkan *tag* (misalnya, versi `v1.0.0`, `v2.0.0`, atau `latest`). | **Rak Album** yang berisi berbagai versi dari satu aplikasi (*image*). |
| **Registry** | Infrastruktur layanan yang menyimpan dan mengelola banyak *Repository* yang berbeda. | **Gedung Gudang** atau **Pusat Distribusi** yang menyimpan ribuan *Repository*. |

### C. Kebutuhan Registry dalam Alur Kerja CI/CD

Mengapa kita tidak cukup hanya menggunakan Git (tempat *Source Code*)? Dalam arsitektur DevOps modern, **pemisahan *code* dan *artefak*** adalah prinsip kunci.

| Kebutuhan | Penjelasan Mendalam | Peran Registry |
| :--- | :--- | :--- |
| **Artefak yang Imutabel** | *Source Code* di Git dapat terus diubah. **Image** (artefak *built*) harus *immutable* (tidak dapat diubah) setelah dibuat. | Menyediakan *tagging* dan *checksum* unik yang menjamin *Image* yang ditarik (*pull*) ke produksi adalah *Image* yang persis sama dengan yang diuji. |
| **Keamanan Jaringan & Akses** | Server CI/CD (misalnya, Drone) membutuhkan *Image* untuk *deployment*. Server ini tidak boleh secara langsung mengakses *Source Code* (Git) untuk mengurangi risiko keamanan. | Bertindak sebagai **titik *handoff* yang aman**. CI *Server* hanya bertugas *PUSH* *Image*, dan *Deployment Server* (misalnya, Kubernetes) hanya bertugas *PULL* *Image*. |
| **Distribusi Cepat** | Lingkungan produksi (Kubernetes *cluster*) mungkin memiliki banyak *Node*. Mendistribusikan *Image* dari Git ke semua *Node* secara bersamaan tidak efisien. | Menyediakan protokol distribusi berkecepatan tinggi (HTTP/2) yang dioptimalkan untuk pengiriman *layer* *container* secara efisien ke *Node* yang membutuhkan. |
| **Pemisahan Peran (Separation of Concerns)** | Memisahkan tanggung jawab *build* (CI Server) dari tanggung jawab *storage* dan *distribution* (Registry). | **Registry** fokus pada penyimpanan, otentikasi, dan keamanan, memungkinkan CI *Server* fokus hanya pada proses *build* dan *test*. |

## 2. Jenis-jenis Image Registry (Publik vs Privat)

Ada dua kategori utama **Image Registry**, dan memilih yang tepat sangat bergantung pada kebutuhan keamanan dan privasi proyek Anda.

### A. Public Registry (Contoh: Docker Hub) 🌍

**Public Registry** adalah layanan yang menyediakan penyimpanan *container images* yang dapat diakses oleh semua orang (publik).

| Kelebihan (+) | Risiko/Kekurangan (-) |
| :--- | :--- |
| **Akses Universal:** Siapa pun dapat menarik (*pull*) *image* tanpa otentikasi (kecuali untuk *repository* privat di dalamnya). | **Keamanan Data:** Jika Anda menyimpan *image* sensitif, risiko kebocoran data (*data leakage*) sangat tinggi. |
| **Ketersediaan Luas:** Menampung ribuan *image* *official* dari vendor (*vendor images*) dan komunitas (misalnya, *image* resmi Ubuntu, Nginx). | **Konten Tidak Terjamin:** Banyak *image* publik yang tidak diverifikasi dan berpotensi mengandung kerentanan (*vulnerability*) atau *malware*. |
| **Gratis (Free Tier):** Umumnya gratis untuk penggunaan dasar. | **Batasan *Pull***: Seringkali menerapkan batasan jumlah *pull* *image* per jam (rate limiting) bagi pengguna tanpa akun berbayar. |

### B. Private Registry (Contoh: Harbor, Amazon ECR) 🔒

**Private Registry** adalah layanan penyimpanan yang memerlukan otentikasi (login) untuk *pull* dan *push* *image*. Layanan ini bisa di-*host* oleh *Cloud Provider* (seperti Amazon ECR) atau di-*deploy* sendiri (*on-premise*/mandiri) seperti **Harbor**.



**Karakteristik Kritis Private Registry**

| Karakteristik | Detail |
| :--- | :--- |
| **A. Keamanan (Security)** | **Wajib untuk Proyek Rahasia/Perusahaan.** *Image* seringkali mengandung **kode rahasia (*proprietary code*)** dan **kunci konfigurasi sensitif**. Menyimpannya di *Private Registry* memastikan *image* tersebut **tidak dapat diakses** oleh publik atau di-*scan* oleh pihak eksternal, menjaga kerahasiaan data proyek. |
| **B. Kontrol Akses (Role-Based Access Control - RBAC)** | **Manajemen Izin Granular.** *Private Registry* memungkinkan Anda mendefinisikan secara ketat siapa yang boleh melakukan operasi tertentu (**Siapa boleh PUSH/PULL/DELETE**). Contoh pengaturan: <br><br>• Tim **Developer** hanya boleh **PUSH** *image*.<br>• Tim **CI/CD** hanya boleh **PULL** *image* untuk *deployment*.<br>• Tim **Auditor** hanya memiliki akses **Read-Only**. |
| **C. Audit dan Kepatuhan** | *Private Registry* menyimpan **log audit** lengkap. Log ini mencatat secara detail siapa yang *push* dan *pull* *image* kapan. Hal ini sangat penting untuk **kepatuhan regulasi industri** (*compliance*), di mana riwayat akses dan perubahan harus dapat dipertanggungjawabkan. |

## 🏗️ 3. Image Registry dalam Arsitektur CI/CD

Dalam arsitektur DevOps modern, **Image Registry** bertindak sebagai jembatan penting yang menghubungkan fase **Build** (Integrasi Berkelanjutan) dengan fase **Deploy** (Pengiriman Berkelanjutan). Peran ini memastikan pemisahan tanggung jawab (*separation of concerns*) dan konsistensi artefak.

### A. Peran Registry dalam Dua Fase Utama

| Fase CI/CD | Posisi Registry | Fungsi Utama |
| :--- | :--- | :--- |
| **Fase Build (CI)** | **Tujuan Akhir (*Push Target*)** | Setelah kode dikompilasi, diuji, dan dikemas menjadi *Container Image* oleh *server* CI (misalnya, Drone CI), *Image* tersebut harus **di-*tag*** dengan versi unik dan **di-*push*** ke *Registry* (Harbor). |
| **Fase Deploy (CD)** | **Sumber Awal (*Pull Source*)** | Lingkungan *deployment* (seperti Kubernetes atau Docker Host) tidak mengakses *source code*. Sebaliknya, ia **menarik (*pull*)** *Image* yang sudah teruji dan ditandatangani langsung dari *Registry* untuk dijalankan sebagai *container*. |

---

### B. Studi Kasus Integrasi: Harbor, Drone CI, dan Kubernetes

Kita menggunakan **Harbor** sebagai *Private Registry* untuk memastikan *image* proyek kita aman. Arsitektur ini menunjukkan aliran *image* yang logis dan otomatis:

#### 1. Drone CI (Build Server) 🛠️

* **Tindakan:** Menerima notifikasi dari Git (kode baru di-*push*).
* **Proses:** Drone CI menjalankan *pipeline* yang terdiri dari:
    * *Clone* kode sumber.
    * *Build* *Docker Image* dari *Dockerfile*.
    * **Penyisipan Kredensial:** Drone menggunakan kredensial yang aman untuk otentikasi ke Harbor.
    * **Output:** Drone **PUSH** *Image* ber-*tag* (`app:v1.0.0`) ke Harbor.

#### 2. Harbor (Image Registry) 💾

* **Tindakan:** Menerima *Image* dari Drone CI.
* **Proses Kritis:** Harbor menyimpan *Image*, mencatat *tag* dan *checksum* uniknya. Karena Harbor memiliki fitur *Vulnerability Scanning* bawaan, *Image* tersebut dapat segera **dipindai kerentanannya** sebelum diizinkan untuk di-*deploy*.

#### 3. Kubernetes (Deployment Engine) 🚢

* **Tindakan:** Menerima instruksi *deployment* (misalnya, *Manifest* YAML) dari Drone CI (melalui *step deployment*).
* **Proses:** Kubernetes mencoba menjalankan *container* berdasarkan *Image* yang ditentukan dalam *Manifest* (`myharbor.domain/project/app:v1.0.0`).
    * Kubernetes **PULL** *Image* tersebut dari Harbor.
    * Jika *Image* berhasil ditarik, Kubernetes membuat *Pod* dan menjalankan *container*.

### C. Manfaat Arsitektur Registry Terpusat

1.  **Immutability:** Karena Kubernetes menarik *Image* dengan *tag* spesifik (`v1.0.0`) dari *Registry*, kita yakin bahwa *Image* yang dijalankan sama persis dengan yang diuji, yang merupakan pondasi penting **DevOps**.
2.  **Efisiensi Jaringan:** *Image* disimpan dekat dengan *cluster* (jika *Registry* di-*host* di *Cloud* yang sama), mempercepat waktu *pull*.
3.  **Audit Trail:** Harbor mencatat kapan *Image* di-*push* oleh Drone dan kapan di-*pull* oleh Kubernetes, menyediakan jejak audit yang lengkap.

## 🛡️ 4. Fitur Lanjutan dan Aspek Kritis (Untuk Diskusi Kritis)

Agar **Image Registry** (seperti Harbor) dapat memenuhi standar keamanan dan efisiensi dalam lingkungan DevOps *enterprise*, *Registry* harus menyediakan lebih dari sekadar penyimpanan. Berikut adalah empat aspek kritis yang wajib dipertimbangkan:

* **Immutability (Ketidakmampuan Diubah):** Ini adalah prinsip fundamental dalam manajemen *container*. Setelah sebuah *Image* di-*tag* (misalnya, `app:v1.0.0`) dan di-*push* ke *Registry*, *Image* tersebut **tidak boleh dimodifikasi atau ditimpa** dengan konten baru. Jika *Image* perlu diperbaiki, ia harus dibuat ulang dan diberi *tag* versi yang baru (misalnya, `app:v1.0.1`). Fitur *Immutability* pada *Registry* (seperti aturan *Replication* di Harbor) memastikan bahwa *Image* yang diuji sama persis dengan yang di-*deploy*, mencegah risiko keamanan akibat perubahan diam-diam (*tampering*).

* **Vulnerability Scanning (Pemindaian Kerentanan):** Sebagian besar *Image* dibangun di atas *base image* (seperti Ubuntu, Alpine) yang mengandung ribuan *library* pihak ketiga. Fitur ini, yang sering diintegrasikan di Harbor menggunakan *tool* seperti **Clair** atau **Trivy**, secara otomatis **memindai setiap *Image* yang masuk** untuk menemukan kerentanan keamanan (*CVEs* - *Common Vulnerabilities and Exposures*) yang sudah diketahui. Dengan fitur ini, *deployment pipeline* dapat dihentikan secara otomatis jika *Image* memiliki kerentanan kritis, menjadikannya gerbang keamanan (*security gate*) pertama dalam CI/CD.

* **Image Signing (Penandatanganan Image):** *Image Signing* adalah proses penambahan tanda tangan kriptografis (digital) pada *Image* yang berhasil dibuat. *Tool* seperti **Notary** digunakan untuk tujuan ini. Tujuannya adalah **memverifikasi keaslian dan integritas *Image***. Ketika Kubernetes menarik *Image* dari *Registry*, ia dapat memverifikasi tanda tangan tersebut. Jika tanda tangan valid, Kubernetes yakin bahwa *Image* tersebut berasal dari sumber terpercaya (CI/CD *pipeline* resmi) dan tidak dimodifikasi oleh pihak ketiga selama transit, mengeliminasi risiko *man-in-the-middle* atau *supply chain attack*.

* **Garbage Collection (Pembersihan Sampah):** *Container Image* dan *layer*-nya dapat menghabiskan ruang *storage* dalam jumlah besar jika tidak dikelola. **Garbage Collection** adalah proses berkala di mana *Registry* secara aman **menghapus *Image layer* yang tidak lagi direferensikan** oleh *Repository* atau *tag* aktif (disebut sebagai *dangling layers*). Fitur ini sangat penting untuk **efisiensi *storage*** dan **mengurangi biaya operasional**, memastikan *Registry* tidak terisi dengan artefak lama yang tidak berguna.



## 💾 5. Instalasi dan Konfigurasi Image Registry

Materi ini dibagi menjadi dua bagian: Instalasi Harbor (Private Registry *Enterprise*) dan pemahaman dasar Docker Registry standar.


### 🛡️ 1. Instalasi Private Registry: Harbor (Solusi *Enterprise*)

Harbor bukan sekadar *registry* sederhana; ia adalah *platform* yang mengemas *core registry* Docker bersama dengan layanan pendukung seperti *Vulnerability Scanner* (Clair/Trivy), *Database* (PostgreSQL), dan *Web UI* di dalam *container* Docker.

#### A. Kebutuhan Sistem (Prasyarat) ⚙️

Sebelum memulai, pastikan *Host Machine* Anda memenuhi kriteria berikut. Harbor membutuhkan lebih banyak *resource* daripada *container* tunggal:

1.  **Docker dan Docker Compose:** Harus sudah terinstal dan berfungsi.
2.  **Resource:** Direkomendasikan minimal **4 GB RAM** dan **2 Core CPU** agar semua komponen Harbor (PostgreSQL, Redis, Core, Scanner) dapat berjalan lancar.
3.  **Port Bebas:** **Port 80 (HTTP)** dan **Port 443 (HTTPS)** harus bebas (*available*) di *Host* untuk diikat oleh Harbor.

-----

#### B. Pengunduhan dan Konfigurasi Dasar 🛠️

#### 1\. Pengunduhan Installer

Unduh *installer* Harbor dan *template* konfigurasi.

```bash
# Unduh installer Harbor (Gunakan versi stabil terbaru)
wget https://github.com/goharbor/harbor/releases/download/v2.8.2/harbor-offline-installer-v2.8.2.tgz

# Ekstrak file
tar xzvf harbor-offline-installer-v2.8.2.tgz
cd harbor
```

#### 2\. Mengedit `harbor.yml`

*File* ini adalah pusat konfigurasi.

```bash
# Salin file template dan edit
cp harbor.yml.tmpl harbor.yml
nano harbor.yml
```

**Konfigurasi Kritis di `harbor.yml`:**

| Parameter | Nilai Contoh | Keterangan |
| :--- | :--- | :--- |
| **`hostname`** | `harbor.projek1.id` | **Wajib** diubah. Ini adalah FQDN (*Fully Qualified Domain Name*) yang akan digunakan oleh Drone dan Kubernetes untuk mengakses *registry*. |
| **`port`** | `80` | Port HTTP (akan dialihkan/redirect). |
| **`https.port`** | `443` | Port HTTPS standar. |

-----

#### C. Fokus Kritis: Menyiapkan Koneksi HTTPS (Keamanan) 🔒

Harbor **harus** diakses melalui HTTPS. Kita akan menggunakan **Self-Signed Certificate** untuk lingkungan lab, yang memerlukan pembuatan kunci pribadi (`.key`) dan sertifikat (`.crt`).

1.  **Generate Sertifikat:** Jalankan perintah *OpenSSL* untuk membuat kunci dan sertifikat. Pastikan `hostname` (`harbor.projek1.id`) digunakan dalam Common Name.

    ```bash
    # Membuat private key dan self-signed certificate
    openssl req -newkey rsa:4096 -nodes -sha256 -keyout harbor.projek1.id.key \
        -x509 -days 365 -out harbor.projek1.id.crt
    ```

2.  **Perbarui `harbor.yml`:** Edit lagi *file* `harbor.yml` dan aktifkan bagian HTTPS, masukkan jalur file sertifikat dan kunci yang baru dibuat:

    ```yaml
    # Buka komentar (uncomment) bagian HTTPS
    https:
      port: 443
      certificate: /path/to/harbor/harbor.projek1.id.crt  # Pastikan path sesuai
      private_key: /path/to/harbor/harbor.projek1.id.key # Pastikan path sesuai
    ```

-----

#### D. Deployment dan Verifikasi 🚀

#### 1\. Menjalankan Instalasi

Jalankan skrip `install.sh`. Skrip ini akan menghasilkan *file* **`docker-compose.yml`** untuk semua layanan Harbor (sekitar 10 *container*).

```bash
sudo ./install.sh
```

#### 2\. Meluncurkan Layanan

Harbor sekarang diluncurkan menggunakan Docker Compose:

```bash
sudo docker compose up -d
```

#### 3\. Verifikasi Status

Pastikan semua *container* Harbor berjalan dengan status `Up`.

```bash
sudo docker compose ps
```

#### 4\. Pengujian Akses UI

Akses *web interface* Harbor dari *browser Host* Anda.

  * **URL:** `https://harbor.projek1.id`
  * **Kredensial Default:**
      * **Username:** `admin`
      * **Password:** `Harbor12345` (Wajib segera diubah setelah *login* pertama).
      * Setelah *login* berhasil, instalasi Harbor selesai dan siap untuk dikonfigurasi lebih lanjut.

### 🧑‍💻 2. Konfigurasi Proyek di Harbor

Konfigurasi ini dilakukan melalui **Web Interface Harbor** (`https://harbor.projek1.id`) setelah Anda *login* sebagai administrator (`admin`/`Harbor12345`).

#### A. Pembuatan Proyek (Repository Utama)

Kita akan membuat *project* baru sebagai wadah untuk semua *container image* terkait proyek Anda.

1.  **Navigasi:** Masuk ke menu **Projects** dan klik **+ New Project**.
2.  **Detail Proyek:**
    * **Project Name:** Masukkan `projek1` (sesuai informasi yang Anda simpan).
    * **Access Level:** Pilih **Private** (Wajib). Ini memastikan *image* hanya dapat diakses dengan otentikasi.
3.  **Finalisasi:** Klik **OK**. Semua *image* yang dibuat oleh Drone CI akan di-*push* ke *path* `harbor.projek1.id/projek1/nama-image`.

---

#### B. Konfigurasi Keamanan dan Otomasi: Robot Account 🤖

**Robot Account** adalah *account* khusus yang dibuat untuk aplikasi otomatis (seperti Drone CI atau Kubernetes), bukan untuk pengguna manusia. Ini adalah *best practice* keamanan karena ia hanya memiliki izin minimal yang dibutuhkan.

1.  **Lokasi:** Masuk ke Proyek `projek1`, lalu navigasi ke menu **Robot Accounts**.
2.  **Pembuatan:** Klik **+ NEW ROBOT ACCOUNT**.
    * **Name:** Beri nama yang jelas, misalnya `drone-ci-robot`.
    * **Expiration:** Tetapkan waktu kedaluwarsa yang sesuai (atau pilih *Never expire* untuk *lab*).
3.  **Manajemen Izin (RBAC):** Berikan izin spesifik yang dibutuhkan Drone CI untuk *pipeline*:
    * **Permission:** Setel izin untuk *Repository* di proyek `projek1`:
        * **Action:** Pilih **Push** dan **Pull**.
    * **Fokus Kritis:** Drone CI hanya perlu **PUSH** *image* yang baru dibuat dan **PULL** *image* dasar (jika ada). Jangan berikan izin **Delete** atau **Scanner** pada Robot Account.
4.  **Simpan Kredensial:** Setelah Robot Account dibuat, Harbor akan menampilkan **Token** unik (seperti *Access Key* dan *Secret Key*). **Salin dan simpan Token ini dengan aman**, karena ini akan digunakan sebagai kredensial rahasia di Drone CI Anda.

---

#### C. Konfigurasi Immutability (Mencegah Penimpaan) 🛡️

Untuk menjamin **Immutability** artefak *container*, kita harus menghentikan Drone CI atau pengguna mana pun untuk menimpa *Image tag* yang sudah ada.

1.  **Lokasi:** Masuk ke Proyek `projek1`, lalu navigasi ke menu **Policy**.
2.  **Pengaturan Immutability:** Cari opsi **Immutable Tag** atau **Prevent Tag Override**.
3.  **Penerapan Aturan:**
    * **Aturan:** Terapkan aturan untuk **semua *tag*** (`*`) atau *tag* produksi tertentu (`v*`).
    * **Aksi:** Aktifkan (centang) kebijakan tersebut.

Setelah diaktifkan, jika Drone CI mencoba me-*push* *Image* baru menggunakan *tag* yang sudah ada di Harbor (misalnya, mencoba me-*push* ulang `v1.0.0`), Harbor akan **menolak** operasi tersebut, memaksa *pipeline* untuk menggunakan *tag* versi yang baru.

---

## 📦 3. Dasar Instalasi Docker Registry Standar

**Docker Registry** standar adalah implementasi dasar dari *Image Registry* yang disediakan oleh komunitas Docker. Meskipun sangat mudah di-*setup*, ia ditujukan untuk tujuan *testing* lokal sederhana dan bukan untuk lingkungan produksi CI/CD yang menuntut keamanan tinggi.

#### A. Instalasi Cepat (Hanya Satu Perintah) 🚀

Instalasi *Registry* standar dilakukan dengan menjalankan *Image* resmi `registry` dari Docker Hub.

```bash
# Menjalankan container registry di port 5000 dan menamai registry-local
docker run -d \
  -p 5000:5000 \
  --restart=always \
  --name registry-local \
  registry:2
```

| Detail | Keterangan |
| :--- | :--- |
| **Port 5000** | Port standar yang digunakan untuk mengakses *Registry*. |
| **`--restart=always`** | Memastikan *Registry* otomatis *restart* jika terjadi kegagalan atau *Host* di-*reboot*. |
| **Akses** | *Registry* ini diakses melalui `localhost:5000`. |

#### Pengujian Cepat: Push dan Pull

Setelah berjalan, Anda dapat menguji fungsionalitasnya:

1.  **Tagging Image Lokal:** `docker tag myapp:latest localhost:5000/myapp:v1`
2.  **Push ke Registry:** `docker push localhost:5000/myapp:v1`
3.  **Pull dari Registry:** `docker pull localhost:5000/myapp:v1`

-----

#### B. Keterbatasan (Mengapa Tidak Cocok untuk Produksi) 🛑

Meskipun fungsionalitas PUSH/PULL tersedia, **Docker Registry standar tidak memiliki fitur manajemen dan keamanan** yang dibutuhkan oleh proyek CI/CD profesional. Ini yang membedakannya secara tajam dari Harbor:

1.  **Tidak Ada Antarmuka Web (UI):** Tidak ada tampilan web untuk melihat daftar *Image*, *Repository*, atau *log*. Pengelolaan sepenuhnya bergantung pada perintah API atau *command line*. Ini membuat audit dan pengelolaan manual sangat sulit.
2.  **Keamanan Minimal (Tidak Ada Otentikasi/RBAC Bawaan):** Secara *default*, *Registry* berjalan tanpa otentikasi. Semua pengguna yang dapat mengakses Port 5000 dapat PUSH atau PULL *Image* apa pun.
      * Untuk menambahkan keamanan (**Basic Auth**), Anda harus mengkonfigurasinya secara manual menggunakan *proxy* terpisah (Nginx/Apache), yang menambah kompleksitas *setup*.
3.  **Tidak Ada Fitur Keamanan Lanjutan:**
      * **Tanpa *Vulnerability Scanning*:** Tidak ada pemindaian otomatis terhadap kerentanan (*CVEs*) pada *Image* yang masuk.
      * **Tanpa *Image Signing*:** Tidak ada mekanisme bawaan untuk memverifikasi keaslian *Image* menggunakan tanda tangan kriptografis.
4.  **Manajemen Storage yang Buruk:** Tidak memiliki fitur **Garbage Collection** otomatis atau efisien untuk membersihkan *layer* *Image* lama yang tidak terpakai, menyebabkan penggunaan *disk space* yang cepat membengkak.

**Kesimpulan:** Docker Registry standar sangat ideal untuk *testing* konsep *container* secara cepat di lingkungan lokal, tetapi Harbor (**Private Registry** kelas *enterprise*) adalah solusi yang dibutuhkan untuk keamanan, pengelolaan, dan kepatuhan dalam alur kerja DevOps yang serius.

---


### 🚀 4. Hands-on: PUSH/PULL dari Host ke Harbor

*Hands-on* ini mengasumsikan Harbor berjalan pada *hostname* **`harbor.projek1.id`** menggunakan HTTPS (Port 443) dengan *self-signed certificate*.

#### A. Konfigurasi Docker Daemon (Mempercayai Sertifikat) 🔒

Karena Anda menggunakan **Self-Signed Certificate** untuk Harbor, **Docker Daemon** di *Host* Anda tidak secara otomatis mempercayainya. Anda harus menambahkan sertifikat ke daftar kepercayaan sistem operasi *Host*.

1.  **Salin Sertifikat:** Salin *file* sertifikat yang Anda buat sebelumnya (`harbor.projek1.id.crt`) ke direktori kepercayaan sistem.

    ```bash
    # Ganti path ini dengan lokasi file sertifikat Anda
    sudo cp /path/to/harbor/harbor.projek1.id.crt /usr/local/share/ca-certificates/

    # Update daftar sertifikat yang dipercaya oleh sistem
    sudo update-ca-certificates
    ```

2.  **Restart Docker Daemon:** Agar perubahan sertifikat berlaku, *daemon* Docker harus di-*restart*.

    ```bash
    sudo systemctl restart docker
    ```

#### B. Login ke Harbor Registry

Setelah *daemon* mempercayai sertifikat, Anda dapat *login* menggunakan kredensial yang dibuat (biasanya akun `admin` atau **Robot Account**).

```bash
# Gunakan hostname yang dikonfigurasi di harbor.yml
docker login harbor.projek1.id 
```

  * **Input yang Diminta:**

      * **Username:** Masukkan `admin` (atau nama **Robot Account** Anda).
      * **Password:** Masukkan *password* admin atau **Token Robot Account** yang Anda simpan.

  * **Hasil yang Diharapkan:** `Login Succeeded`

-----

#### C. Tagging dan PUSH Image ke Harbor

Kita akan menggunakan *Image* dasar (`hello-world` atau `nginx`) untuk di-*push* ke *Repository* `projek1` yang sudah Anda buat di Harbor.

1.  **Pull Image Dasar:** Tarik *image* dasar dari Docker Hub.

    ```bash
    docker pull nginx:latest
    ```

2.  **Tagging Image Lokal:** Beri *tag* baru pada *image* yang sudah ditarik, menggunakan format wajib Harbor: **`[HOSTNAME]/[PROJECT_NAME]/[REPOSITORY]:[TAG]`**.

    ```bash
    # Ganti 'projek1' dengan nama proyek Anda di Harbor
    docker tag nginx:latest harbor.projek1.id/projek1/nginx-web:v1.0.0
    ```

3.  **PUSH Image:** Dorong (*push*) *Image* yang sudah di-*tag* ke Harbor.

    ```bash
    docker push harbor.projek1.id/projek1/nginx-web:v1.0.0
    ```

      * **Verifikasi:** Anda akan melihat proses *layer by layer* diunggah ke *Registry*.

-----

#### D. Verifikasi Akhir (UI dan CLI)

1.  **Verifikasi Web Interface (UI):**

      * Buka *browser* dan akses `https://harbor.projek1.id`.
      * Masuk ke menu **Projects** \> **projek1** \> **Repositories**.
      * Pastikan *Repository* baru **`nginx-web`** muncul, dan di dalamnya terdapat *Image* dengan **`Tag: v1.0.0`**.

2.  **Verifikasi PULL dari CLI:**

      * Hapus *Image* lokal Anda.
      * ```bash
        docker rmi harbor.projek1.id/projek1/nginx-web:v1.0.0
        ```
      * Tarik (*pull*) kembali *Image* dari Harbor. Jika berhasil, *Registry* berfungsi sepenuhnya.
      * ```bash
        docker pull harbor.projek1.id/projek1/nginx-web:v1.0.0
        ```