# CI/CD Pipeline (Advanced)

# Bagian I: Konsep dan Strategi Workflow (Landasan Teori) 💡

## 💡 I.A. Definisi Workflow & Branching Strategy

### 1\. Definisi Workflow CI/CD

**Workflow CI/CD** (Alur Kerja CI/CD) adalah serangkaian langkah, aturan, dan praktik yang mendefinisikan bagaimana kode dikembangkan, diintegrasikan, dan dikirimkan (*delivered*) kepada pengguna.

Dalam konteks Git, *workflow* ini diimplementasikan melalui **Branching Strategy** (Strategi Percabangan). Strategi Percabangan mengatur:

1.  Kapan *feature* baru dikerjakan (membuat *feature branch*).
2.  Bagaimana *feature* tersebut diuji dan diintegrasikan kembali ke kode utama (*main branch*).
3.  Kapan *deployment* ke lingkungan tertentu (Dev, Staging, Prod) harus dilakukan.

### 2\. Peran Kritis Workflow terhadap Pipeline

Pilihan *workflow* secara langsung menentukan **kapan, di mana, dan apa yang harus dilakukan** oleh **Drone CI *Pipeline*** Anda.

Setiap *step* dalam *pipeline* Drone CI tidak boleh berjalan sembarangan. Ia harus terikat pada kondisi *branch* atau *tag* tertentu agar proses *deployment* terkontrol.

| Aksi yang Dicontohkan | Pemicu (Workflow Requirement) |
| :--- | :--- |
| **Integrasi Berkelanjutan (CI)** | Kode di-*push* ke *feature branch* atau *Pull Request* dibuka. |
| **Deployment ke Staging** | Kode di-*merge* atau di-*push* ke *branch* `staging`. |
| **Deployment ke Produksi** | Kode di-*tag* dengan versi rilis (`v1.0.0`) atau di-*merge* ke *branch* `production`. |

### 3\. Penerjemahan Workflow ke Kondisi Drone CI (`when:`)

Drone CI menggunakan blok **`when:`** untuk menerapkan logika *workflow*. Blok ini menentukan **kondisi** yang harus dipenuhi oleh *event* Git (push, tag, pull request) agar *step* atau seluruh *pipeline* berjalan.

#### Struktur Dasar Blok `when:`

| Kondisi | Deskripsi | Contoh Penggunaan |
| :--- | :--- | :--- |
| **`branch:`** | Membatasi *step* hanya berjalan pada *branch* tertentu. | `branch: [ main, staging ]` |
| **`event:`** | Membatasi *step* hanya berjalan pada tipe *event* tertentu. | `event: [ push, pull_request ]` |
| **`status:`** | Membatasi *step* hanya berjalan setelah *step* sebelumnya memiliki status tertentu. | `status: [ success ]` |
| **`trigger:`** | Mengubah mode pemicuan menjadi manual. | `trigger: manual` |

#### Contoh Penerapan Workflow di `.drone.yml`

Asumsikan kita menggunakan **GitLab Flow** dan memiliki *step* `deploy-staging`.

```yaml
# ... (File .drone.yml) ...

# Step ini hanya akan berjalan jika event-nya adalah 'push'
# DAN branch-nya adalah 'staging'.
- name: deploy-ke-staging
  image: lalk/drone-kubectl
  # ... settings ...
  when:
    branch: [ staging ]
    event: [ push ]
```

### Bagan: Hubungan Branching Strategy dengan Drone CI Trigger

Bagan berikut mengilustrasikan bagaimana strategi percabangan diterjemahkan menjadi *trigger* di *pipeline* CI/CD, yang merupakan inti dari desain *workflow*.

```mermaid
graph TD
    subgraph Workflow (GitLab Flow)
        FE[Feature Branch] --> |1. Push Code| CI[Continuous Integration]
        CI --> PR(Pull Request)
        PR --> |2. Merge Approved| MAIN[main Branch]
        MAIN --> |3. Merge Code| STG[staging Branch]
        STG --> |4. Approval & Merge| PROD[production Branch]
    end

    subgraph Pipeline Triggers (Drone CI)
        CI --> |A. event: [push]| STEP_TEST[Step: Test]
        MAIN --> |B. branch: [main]| STEP_PUSH[Step: Push Image to Harbor]
        STG --> |C. branch: [staging]| STEP_DEPLOY_STG[Step: Deploy to K8s: Namespace STAGING]
        PROD --> |D. branch: [production]| STEP_DEPLOY_PROD[Step: Deploy to K8s: Namespace PROD]
    end

    style CI fill:#a2e8c2,stroke:#333
    style MAIN fill:#c4a2e8,stroke:#333
    style STG fill:#e8e8a2,stroke:#333
    style PROD fill:#e8a2a2,stroke:#333
    style STEP_TEST fill:#9cc
    style STEP_PUSH fill:#cc9
    style STEP_DEPLOY_STG fill:#cc99cc
    style STEP_DEPLOY_PROD fill:#ffcccc
```

**Penjelasan Bagan:**

  * Setiap *branch* dalam *workflow* memiliki peran tunggal.
  * Peran tersebut diterjemahkan menjadi **kondisi pemicu** (`when:`) di Drone CI (A, B, C, D) untuk menjalankan *step* spesifik (misalnya, hanya *branch* `staging` yang boleh memicu Deployment ke lingkungan *Staging*).
---

## 💡 I.B. Perbandingan Model Git (Branching Strategy)

Memilih model *branching* yang tepat sangat krusial, karena ia menentukan frekuensi *deployment* dan kompleksitas manajemen rilis.

### 1. GitFlow: Model Tradisional dan Kaku 👴

GitFlow dirancang untuk proyek dengan siklus rilis yang panjang dan terencana (*scheduled releases*). Ini adalah model yang paling kompleks karena menggunakan banyak *branch* berumur panjang.

| Aspek | Deskripsi | Implikasi CI/CD |
| :--- | :--- | :--- |
| **Filosofi** | *Release-based*. Fokus pada isolasi *development* dari kode produksi yang stabil. | *Deployment* ke produksi terjadi jarang, hanya dari *branch* `release` atau `master`. |
| **Branch Kunci** | **`master`** (Produksi stabil) dan **`develop`** (Integrasi fitur). Ditambah `feature/`, `release/`, dan `hotfix/`. | Drone harus memiliki *pipeline* yang berbeda untuk setiap jenis *branch*. |
| **Kompleksitas** | **Tinggi.** Proses *merging* rumit, sering membutuhkan *cherry-picking* dan berpotensi menyebabkan *merge conflict* besar. | *Pipeline* menjadi lambat dan butuh intervensi manual yang tinggi. |
| **Ideal Untuk** | Aplikasi *enterprise* yang membutuhkan persetujuan formal dan rilis terjadwal (misalnya, software yang dikirimkan ke klien). |

---

### 2. GitHub Flow: Model Sederhana dan Cepat 💨

GitHub Flow dirancang untuk kesederhanaan dan *Continuous Deployment* (CD). Ini adalah model yang direkomendasikan untuk tim yang ingin merilis sering dan cepat.

| Aspek | Deskripsi | Implikasi CI/CD |
| :--- | :--- | :--- |
| **Filosofi** | **`main` selalu *deployable***. Fokus pada *commit* kecil, sering, dan integrasi cepat. | Drone menjalankan **CD otomatis** segera setelah *merge* ke `main`. |
| **Branch Kunci** | **`main`** (Satu-satunya *branch* berumur panjang, selalu stabil). Ditambah *feature branch* jangka pendek. | Hanya perlu satu *pipeline* utama yang berfokus pada *branch* `main`. |
| **Kompleksitas** | **Rendah.** Proses sangat mudah. *Rollback* dilakukan dengan me-*revert* *commit* di `main`. | *Pipeline* sangat cepat. Risiko *deployment* dikelola melalui *unit tests* dan *code review* pada setiap *Pull Request*. |
| **Ideal Untuk** | Aplikasi *web* atau layanan mikro (*microservices*) dengan *deployment* berkelanjutan. |

---

### 3. GitLab Flow: Model Fleksibel dan Terkontrol (Fokus Lingkungan) 🛡️

GitLab Flow memberikan kontrol *environment* yang lebih terstruktur daripada GitHub Flow tanpa kompleksitas GitFlow. Ini adalah model yang sangat direkomendasikan saat Anda memiliki **lingkungan Dev, Staging, dan Production** yang terpisah.

| Aspek | Deskripsi | Implikasi CI/CD |
| :--- | :--- | :--- |
| **Filosofi** | **Lingkungan = Branch.** Kontrol rilis dicapai dengan memindahkan perubahan antar *branch* yang mewakili lingkungan. | Drone dapat membedakan tujuan *deployment* berdasarkan *branch* pemicu. |
| **Branch Kunci** | **`main`** (Kode terbaru stabil), **`staging`**, **`production`**. Ditambah *feature branch* jangka pendek. | Membutuhkan **tiga *step* deployment** berbeda di Drone, masing-masing dengan kondisi `when: branch: [nama_branch]`. |
| **Kompleksitas** | **Sedang.** Lebih kompleks dari GitHub Flow, tetapi lebih mudah dikelola daripada GitFlow. | Memungkinkan persetujuan manual (**Manual Approval**) hanya pada *branch* `staging` atau `production`. |
| **Ideal Untuk** | Proyek yang membutuhkan pengujian menyeluruh (*E2E testing*) di lingkungan *staging* sebelum rilis ke produksi. |

### Bagan Perbandingan Model Git 

| Fitur | GitFlow | GitHub Flow | **GitLab Flow** |
| :--- | :--- | :--- | :--- |
| **Jumlah Long-lived Branches** | Banyak (`master`, `develop`, `release`) | Satu (`main`) | Tiga atau Lebih (`main`, `staging`, `production`) |
| **Frekuensi Rilis** | Rendah (Terjadwal) | Tinggi (Sering) | Sedang hingga Tinggi (Environment-based) |
| **Deployment Trigger** | *Merge* ke `release` | *Merge* ke `main` | *Merge* ke *branch* **spesifik lingkungan** |
| **Otoritas Kode** | `master` = Produksi | `main` = Produksi | `production` = Produksi |

Model **GitLab Flow** sangat relevan untuk *challenge* mahasiswa Anda karena secara eksplisit memerlukan pemisahan *namespace* dan kontrol alur yang berbeda.

---

## 💡 I.C. Tahapan Standar CI/CD (Stages)

Tahapan (**Stages**) mendefinisikan urutan logis dari aksi yang harus dilakukan *pipeline* pada kode. Setiap *stage* harus sukses agar *pipeline* dapat melaju ke *stage* berikutnya. Dalam Drone CI, urutan *steps* (`steps:`) dalam `.drone.yml` bertindak sebagai *stages*.

| No. | Stage (Tahapan) | Tujuan Kritis | Tools dan Aksi Khas di Drone CI |
| :--- | :--- | :--- | :--- |
| **1.** | **Source** | Mendapatkan kode sumber yang baru di-*push*. | Dipicu oleh **Gitea Webhook**. Drone secara otomatis melakukan `git clone` ke *workspace* Runner. |
| **2.** | **Build** | Mengkompilasi kode sumber menjadi artefak yang dapat dieksekusi. | Menjalankan perintah kompilasi (misalnya, `go build`, `npm run build`, `mvn package`) di *container* Runner. Hasilnya adalah *executable* yang siap di-*package*. |
| **3.** | **Test** | Memverifikasi fungsionalitas dan kualitas kode. | Menjalankan **Unit Tests** dan **Linting Tools** (seperti `go test` atau *pytest*). **Quality Gate Pertama:** Jika tes gagal, *pipeline* berhenti di sini. |
| **4.** | **Package / Image Build** | Mengemas aplikasi dan lingkungannya ke dalam *image* kontainer. | Menggunakan **plugins/docker** untuk menjalankan **`docker build`**. Pada tahap ini, *image* diberi *tag* unik (misalnya, `COMMIT_SHA`). |
| **5.** | **Publish** | Menyimpan *image* yang sudah di-*build* dan diberi *tag* ke *Registry*. | Menggunakan **plugins/docker** untuk menjalankan **`docker push`** ke **Harbor** atau **Docker Hub**, menggunakan *Secrets* yang sesuai (`HARBOR_ROBOT_TOKEN`). |
| **6.** | **Security Scan** | Menganalisis *image* yang di-*publish* dari kerentanan keamanan (*vulnerability*). | **Quality Gate Kedua:** Menggunakan *plugin* seperti **Trivy**. Jika kerentanan **HIGH/CRITICAL** ditemukan, *pipeline* mengembalikan *exit code 1* dan menghentikan proses *deployment*. |
| **7.** | **Deploy** | Menerapkan *image* yang telah lolos *scan* ke lingkungan target (misalnya, Dev/Staging). | Menggunakan **drone-kubectl** atau **drone-helm** untuk memperbarui *manifest* (misalnya, `kubectl set image...`) di Kubernetes. Hanya berjalan jika semua *stage* sebelumnya sukses. |

---

### Pentingnya Urutan Stages

* **Efisiensi:** Jika *Unit Test* gagal pada **Stage 3**, tidak ada gunanya membuang waktu untuk membangun *image* besar di **Stage 4** atau menunggu *deployment* di **Stage 7**. *Pipeline* dirancang untuk gagal secepat mungkin (*fail fast*).
* **Keamanan:** **Stage 6 (Security Scan)** wajib ditempatkan **setelah Publish** karena ia harus memindai artefak yang sama persis yang akan digunakan untuk *deployment*. Jika *scan* ini gagal, *deployment* otomatis diblokir, mencegah kode yang rentan masuk ke *cluster*.

Mahasiswa harus memastikan bahwa setiap *step* dalam `.drone.yml` mereka sesuai dengan urutan logis ini dan menggunakan kondisi pemicu kegagalan yang benar.

---

## 💡 I.D. Prinsip Least Privilege & RBAC

Ketika sistem otomatis (seperti Drone CI) berinteraksi dengan infrastruktur kritis (seperti Kubernetes), penerapan kontrol akses yang ketat adalah fundamental.

### 1. Prinsip Least Privilege (Izin Minimal) 🔒

**Prinsip Least Privilege (PoLP)** menyatakan bahwa setiap pengguna, program, atau proses (dalam hal ini, Drone CI Runner) harus diberikan hak akses minimal yang diperlukan untuk menjalankan fungsinya, dan tidak lebih.

* **Tujuan:** Membatasi potensi kerusakan. Jika *pipeline* CI/CD disusupi atau salah dikonfigurasi, PoLP memastikan kerusakan yang ditimbulkan hanya terbatas pada *resource* yang boleh diaksesnya.
* **Implikasi pada Drone:** *Service Account Token* yang kita gunakan untuk otentikasi Drone ke Kubernetes **tidak boleh memiliki izin *cluster-admin***. Token tersebut hanya boleh memiliki izin untuk `update` atau `patch` *Deployment* di *namespace* tertentu saja.

---

### 2. Penerapan Menggunakan RBAC (Role-Based Access Control) di Kubernetes

RBAC adalah mekanisme otorisasi standar di Kubernetes yang memungkinkan Anda mendefinisikan siapa (Subjek) yang dapat melakukan apa (Kata Kerja/Aksi) pada *resource* apa (Objek) dan di mana (*Namespace*).

Untuk menerapkan PoLP pada Drone CI, kita menggunakan tiga komponen RBAC utama:

#### A. Service Account (SA)
* **Peran:** Identitas non-manusia yang digunakan oleh aplikasi (Drone Runner) untuk otentikasi ke Kubernetes API Server.
* **Contoh:** Kita menggunakan `ServiceAccount` bernama **`drone-deployer`** di *namespace* `dev`.

#### B. Role (Peran)
* **Peran:** Mendefinisikan sekumpulan izin yang spesifik dan terbatas. *Role* bersifat **terikat pada *namespace***.
* **Contoh:** Kita membuat `Role` yang hanya mengizinkan aksi `get`, `list`, `patch`, dan `update` pada *resource* `deployments` dan `pods`.

#### C. RoleBinding (Pengikatan Peran)
* **Peran:** Mengikat (`bind`) *Service Account* (Subjek) dengan *Role* (Peran) di *namespace* tertentu.
* **Contoh:** `RoleBinding` akan mengikat `ServiceAccount/drone-deployer` dengan `Role/deployment-updater` di *namespace* **`dev`**.

---

### 3. Pentingnya Pemisahan Izin Berdasarkan Namespace (Multi-Namespace)

Dalam skenario **GitLab Flow** yang menggunakan *namespace* terpisah (`dev` dan `staging`), PoLP diterapkan dengan memisahkan otoritas *Service Account* di setiap lingkungan:

| Lingkungan | Namespace K8s | Izin yang Dibutuhkan | Penerapan RBAC |
| :--- | :--- | :--- | :--- |
| **Development** | **`dev`** | Izin penuh untuk *Update* dan *Delete* **Deployment** dan *Service*. | `RoleBinding` terikat pada **`namespace: dev`**. |
| **Staging** | **`staging`** | Izin hanya untuk *Update* **Deployment**. *Deletion* dilarang. | `RoleBinding` terikat pada **`namespace: staging`** dengan *Role* yang lebih ketat. |

**Kesimpulan Kritis:** Meskipun Drone CI menggunakan **Token Service Account yang sama** untuk semua *deployment*, tingkat izin yang dimiliki token tersebut pada akhirnya ditentukan oleh **`RoleBinding`** yang mendasarinya di setiap *namespace*. Ini adalah cara Kubernetes memastikan bahwa *pipeline* tidak sengaja menghapus *resource* Staging saat seharusnya hanya memodifikasi *resource* Dev.

--

# Bagian II: Tahapan Pipeline & Tools (Eksekusi Teknis) ⚙️

---

## 1\. Stage: Source (Pemicu & Kloning Kode) 📥

Tahap **Source** adalah tahap pertama dan merupakan pemicu utama *pipeline*. Tugasnya adalah menginformasikan Drone CI tentang adanya perubahan kode dan membawa kode sumber ke dalam lingkungan eksekusi (*Drone Runner*).

| Fokus Aksi | Deskripsi Detail | Tools & Plugin Drone CI |
| :--- | :--- | :--- |
| **Pemicu (Trigger)** | Perubahan kode (misalnya, `git push`) di *repository* Gitea. | **Gitea Webhook.** Gitea mengirim *payload* HTTP ke Drone CI yang berisi detail *commit*. |
| **Otentikasi** | Drone CI memverifikasi *webhook* dari Gitea (menggunakan *Shared Secret* yang dikonfigurasi saat integrasi awal). | **Drone CI Server.** Bertanggung jawab memvalidasi *request* dari Gitea. |
| **Kloning Kode** | Drone CI Runner secara otomatis mengkloning *repository* ke dalam *workspace*-nya. | **Git CLI** (Bawaan Drone Runner). Drone menggunakan kredensial internal untuk kloning. |
| **Environment Variables** | Drone secara otomatis mengisi variabel lingkungan (`DRONE_COMMIT_SHA`, `DRONE_BRANCH`, dll.) yang akan digunakan oleh *step* selanjutnya. | **Drone Runner.** Menyediakan konteks eksekusi. |

> **Implementasi Kritis:** Tahap ini terjadi secara implisit ketika *pipeline* Drone CI dimulai. Mahasiswa tidak perlu menulis *step* khusus untuk *cloning* kode.

-----

## 2\. Stage: Build (Kompilasi dan Persiapan Artefak) 🧱

Tahap **Build** adalah ketika kode sumber mentah diubah menjadi artefak yang dapat dijalankan (*executable* atau *library*).

| Fokus Aksi | Deskripsi Detail | Tools & Plugin Drone CI |
| :--- | :--- | :--- |
| **Kompilasi** | Menjalankan perintah kompilasi (misalnya, mengubah kode Go menjadi biner, atau JavaScript/TypeScript menjadi *bundle*). | **Base Compiler Images.** *Image* Docker yang berisi *toolchain* yang diperlukan: **`golang:latest`**, **`node:lts`**, **`maven:latest`**, dll. |
| **Output Artefak** | Hasil kompilasi disimpan di dalam *workspace* Runner. | *File executable* atau *file* terkompilasi. |
| **Dependency Management** | Memastikan semua *library* eksternal diunduh dan dipaketkan. | Perintah seperti `go mod download`, `npm install`, atau `mvn clean install`. |

#### Contoh Step Build di `.drone.yml` (Untuk Aplikasi Go)

```yaml
- name: build-golang-app
  image: golang:1.21-alpine # Menggunakan base image Go
  commands:
    # Mengunduh dependencies
    - go mod download
    # Mengkompilasi dan membuat biner
    - CGO_ENABLED=0 go build -o app ./cmd/main.go
    # Hasil biner 'app' kini siap untuk tahap Package/Image Build
```
---

## 3\. Test (Quality Gate) 🧪

Tahap **Test** bertujuan untuk memverifikasi fungsionalitas, keandalan, dan kualitas kode sumber yang baru saja di-*build*. Jika tahap ini gagal, *pipeline* **wajib berhenti** (*fail fast*), mencegah *image* yang mengandung *bug* atau kerentanan dibuat dan didorong ke *registry*.

### Fokus Aksi Kritis:

1.  **Validasi Fungsional:** Memastikan setiap bagian kode (unit) bekerja sesuai harapan.
2.  **Validasi Kualitas:** Memeriksa gaya penulisan kode, kepatuhan standar, dan praktik terbaik (*best practices*).

### Jenis-jenis Pengujian di Tahap CI:

| Jenis Pengujian | Tujuan | Tools Umum (Sesuai Bahasa Pemrograman) |
| :--- | :--- | :--- |
| **Unit Testing** | Menguji komponen terkecil dari kode (misalnya, satu fungsi atau metode) secara terisolasi. | **PyTest** (Python), **Go Test** (GoLang), **JUnit** (Java), **Jest/Mocha** (JavaScript). |
| **Linting & Formatting** | Menganalisis kode untuk *style* yang buruk, kesalahan sintaksis, atau pelanggaran standar coding. | **ESLint**, **Pylint**, **GoLint**. |
| **Integrity Testing** | Memastikan modul-modul yang berbeda bekerja sama dengan benar (walaupun seringkali masuk di *stage* terpisah). | *Framework* yang dapat mensimulasikan interaksi antar layanan. |
| **SAST (Static Application Security Testing)** | Memindai kode sumber untuk kerentanan keamanan yang umum (misalnya, *SQL Injection* atau *Cross-Site Scripting*). | **SonarQube Scanner** (memerlukan server terpisah), **Bandit** (untuk Python), **GoSec** (untuk Go). |

### Implementasi Tools di Drone CI

Di Drone CI, pengujian dilakukan dengan menjalankan *tools* pengujian melalui blok `commands:` dalam *step* khusus.

#### Contoh Step Test di `.drone.yml` (Menggunakan Go dan PyTest)

**Skenario 1: Go Test**

```yaml
- name: run-unit-tests
  image: golang:1.21-alpine # Gunakan image yang sama dengan saat Build
  commands:
    # 1. Jalankan unit test, -v untuk verbose, dan pastikan test berjalan
    - go test -v ./... 
    
    # 2. Opsional: Jalankan linting
    - go vet ./...
  when:
    # Step ini berjalan di semua push ke branch develop atau feature
    branch: [ main, develop ]
```

**Skenario 2: Python (PyTest)**

```yaml
- name: run-python-tests
  image: python:3.11-slim
  commands:
    # 1. Instal dependencies test
    - pip install -r requirements.txt
    - pip install pytest pylint
    
    # 2. Jalankan unit test
    - pytest tests/
    
    # 3. Jalankan linting
    - pylint src/app.py
```

### Konsep Penting: Quality Gate

  * **Kegagalan Otomatis:** Semua *tools* pengujian yang digunakan di tahap ini (PyTest, Go Test, SonarQube Scanner) harus dikonfigurasi untuk mengembalikan ***exit code 1* (Error)** jika pengujian gagal, *bug* ditemukan, atau ambang batas kualitas dilanggar.
  * **Blokir Pipeline:** Jika *exit code 1* dikembalikan oleh *step* **Test**, Drone CI secara otomatis menandai *pipeline* sebagai **Failed** dan tidak akan melanjutkan ke **Stage 3: Package/Publish**. Ini memastikan hanya kode yang lulus uji yang dapat menjadi *image* kontainer.

---

### Tahapan Pipeline & Tools: 3. Package & Publish 📦

Tahap **Package & Publish** melibatkan dua langkah terpisah: (1) **Packaging** (membentuk *image* Docker) dan (2) **Publishing** (mendorong *image* ke *registry*).

## 4\. Stage: Package (Membangun Image Docker)

Tujuan dari tahap ini adalah untuk menggabungkan kode biner yang sudah di-*build* dan semua dependensi sistem yang dibutuhkan ke dalam format **Docker Image**.

| Fokus Aksi | Deskripsi Detail | Tools dan Plugin Drone CI |
| :--- | :--- | :--- |
| **Penyalinan Artefak** | Mengambil *executable* yang sudah dibuat di Tahap Build dan menyalinnya ke dalam *image* melalui **Dockerfile**. | **Dockerfile** (Dokumen instruksi) |
| **Image Tagging** | Memberi label unik pada *image*. Label ini wajib menggunakan identifikasi *commit* Git untuk memastikan ketertelusuran (*traceability*). | **Variabel Lingkungan Drone:** `plugins/docker` secara otomatis menggunakan `DRONE_COMMIT_SHA` untuk *tagging*. |
| **Image Building** | Menjalankan perintah `docker build` di dalam Drone Runner. | **plugins/docker** (Plugin resmi Drone) atau Docker CLI |

**Implementasi Kritis: Penggunaan `plugins/docker`**

Untuk menyederhanakan proses, Drone CI menyediakan *plugin* resmi. Kita akan menggunakan *plugin* **`plugins/docker`** dan memastikan *tag* (label) menggunakan 8 karakter pertama dari *commit* SHA:

```yaml
# Step: Package (Build Image)
- name: build-image
  image: plugins/docker:latest
  settings:
    # Repo tujuan di registry
    repo: harbor.projek1.id/projek1/projek1-deployment 
    # Tagging: menggunakan 8 karakter SHA (unik) dan 'latest'
    tags: [ ${DRONE_COMMIT_SHA:0:8}, latest ] 
    # Path ke Dockerfile
    dockerfile: Dockerfile
```

-----

## 5\. Stage: Publish (Mendorong Image ke Registry)

Setelah *image* berhasil dibuat, tahap **Publish** bertanggung jawab untuk menyimpan *image* tersebut di tempat yang dapat diakses oleh *cluster* Kubernetes (yaitu, *Container Registry*).

| Fokus Aksi | Deskripsi Detail | Tools dan Plugin Drone CI |
| :--- | :--- | :--- |
| **Otentikasi Registry** | Drone Runner harus *login* ke *registry* (Harbor atau Docker Hub) menggunakan kredensial non-manusia (Robot Account). | **Secrets Drone CI:** Digunakan untuk menyuntikkan `HARBOR_ROBOT_USERNAME` dan `HARBOR_ROBOT_TOKEN`. |
| **Image Push** | Menjalankan perintah `docker push` ke *registry* yang dituju. | **plugins/docker** |
| **Aksesibilitas** | Memastikan *image* yang didorong dapat ditarik (*pull*) oleh Kubernetes. | **Harbor (Registry Privat)** atau Docker Hub. |

**Contoh Step Publish di `.drone.yml` (Terintegrasi)**

Dalam praktiknya, *plugin* `plugins/docker` dapat menjalankan aksi *build* dan *push* dalam satu *step* jika diberikan kredensial yang tepat:

```yaml
# Step: Package dan Publish (Build & Push)
- name: build-and-push-harbor
  image: plugins/docker:latest
  settings:
    # URL Registry dan nama Repository
    repo: harbor.projek1.id/projek1/projek1-deployment
    tags: [ ${DRONE_COMMIT_SHA:0:8}, latest ] 
    # Kredensial Otentikasi
    username: { from_secret: HARBOR_ROBOT_USERNAME } 
    password: { from_secret: HARBOR_ROBOT_TOKEN } 
    # Insecure (Opsional: hanya jika Harbor menggunakan self-signed certificate)
    # insecure: true 
  # Step ini hanya berjalan jika Stage 2 (Test) sukses
  when:
    status: [ success ]
```

**Penting:** Penggunaan *secrets* (`from_secret:`) memastikan bahwa kredensial sensitif tidak terekspos di dalam *file* `.drone.yml`. Kredensial ini harus sudah didefinisikan di pengaturan *repository* Drone CI.

---

## 6\. Security Scan (Quality Gate) 🛡️

Tahap **Security Scan** harus dijalankan **setelah** *image* berhasil di-*push* ke *Registry* (Tahap 3). Tujuannya adalah menganalisis semua komponen di dalam *image* (OS, *libraries*, *dependencies*) terhadap database kerentanan publik (CVE).

### Fokus Aksi Kritis:

1.  **Pemindaian Mendalam:** Menganalisis *image* yang baru dibuat (ditandai dengan `COMMIT_SHA` unik).
2.  **Pemicu Kegagalan:** Jika ditemukan kerentanan dengan tingkat keparahan **HIGH** atau **CRITICAL**, *tools* harus mengembalikan *exit code 1* untuk menghentikan seluruh *pipeline* **sebelum** *deployment*.

### Tools Utama yang Digunakan:

| Tool | Deskripsi dan Implementasi |
| :--- | :--- |
| **Trivy** | **Direkomendasikan.** *Scanner* *open-source* dari Aqua Security yang cepat dan ringan. Trivy mudah dijalankan sebagai *step* mandiri di Drone CI. |
| **Clair** | *Tool* pemindai yang terintegrasi dengan Harbor. Jika mahasiswa menggunakan Harbor, hasil *scan* Clair dapat dilihat di *web interface* Harbor (walaupun menghentikan *pipeline* di Drone memerlukan konfigurasi tambahan). |

### Implementasi Tools di Drone CI (Menggunakan Trivy)

Untuk mengimplementasikan *Quality Gate* ini, kita menggunakan *image* Trivy dan menyuntikkan kredensial Harbor (jika *registry* privat) agar Trivy dapat menarik (*pull*) *image* tersebut untuk dianalisis.

#### Contoh Step Security Scan di `.drone.yml`

```yaml
# Step ini wajib berjalan setelah Stage Publish (Push) sukses
- name: security-scan-trivy
  image: aquasec/trivy:latest # Image Trivy resmi
  environment:
    # Kredensial Registry Privat (Wajib jika menggunakan Harbor)
    TRIVY_USERNAME: { from_secret: HARBOR_ROBOT_USERNAME } 
    TRIVY_PASSWORD: { from_secret: HARBOR_ROBOT_TOKEN }
  commands:
    # 1. Definisikan Image yang akan dipindai (gunakan tag SHA yang sama)
    - IMAGE_TO_SCAN=harbor.projek1.id/projek1/projek1-deployment:${DRONE_COMMIT_SHA:0:8}
    - echo "Starting Trivy scan on $IMAGE_TO_SCAN..."
    
    # 2. Perintah Pemindaian Kritis:
    #    --exit-code 1: Menjadikan step GAGAL jika kondisi dipenuhi.
    #    --severity: Hanya fokus pada level kerentanan Tinggi dan Kritis.
    - trivy image --exit-code 1 --severity HIGH,CRITICAL --ignore-unfixed $IMAGE_TO_SCAN
  when:
    # Hanya berjalan jika push ke main/staging sukses
    status: [ success ]
```

### Konsep Kritis: Memblokir Deployment

Penggunaan *flag* **`--exit-code 1`** adalah **kunci** dari *Quality Gate* ini. Jika Trivy menemukan kerentanan `HIGH` atau `CRITICAL` pada *image* tersebut, ia akan keluar dengan kode *error 1*, menyebabkan *step* ini gagal. Drone CI kemudian **tidak akan melanjutkan** ke **Tahap 5 (Deploy)**, sehingga *image* yang rentan tidak pernah mencapai Kubernetes *cluster* Anda.

---

## 7\. Deployment (Penerapan) 🚀

Tahap **Deployment** adalah aksi terakhir dalam *pipeline* CI/CD. Tujuannya adalah menginstruksikan Kubernetes *Cluster* untuk mengganti *image* lama yang sedang berjalan dengan *image* baru yang telah berhasil di-*push* di Tahap **Publish** (Tahap 3) dan lolos **Security Scan** (Tahap 4).

### Fokus Aksi Kritis:

1.  **Akses Aman:** Drone Runner harus berotentikasi ke Kubernetes API Server menggunakan kredensial yang minimal (Prinsip *Least Privilege*).
2.  **Pembaruan *Resource*:** Mengubah *tag* *image* pada objek *Deployment* Kubernetes.
3.  **Kontrol Lingkungan:** Memastikan *deployment* hanya menargetkan *namespace* yang sesuai dengan *branch* yang memicu (*trigger*).

### Tools Utama yang Digunakan:

| Tool | Peran Kritis |
| :--- | :--- |
| **Drone-kubectl Plugin** | Sebuah *wrapper* yang menyederhanakan eksekusi perintah `kubectl` dari dalam Drone CI *pipeline*. |
| **KUBE\_TOKEN** | Kredensial rahasia yang berasal dari Kubernetes **Service Account** (SA) dan digunakan oleh *plugin* untuk berotentikasi ke API Server. |

### 1\. Mekanisme Otentikasi Aman (*Service Account Token*)

Seperti yang dibahas di **Bagian I.D (RBAC)**, *deployment* harus dilakukan oleh identitas yang memiliki izin terbatas:

1.  **Service Account (SA):** Di Kubernetes, SA dibuat (misalnya, `drone-deployer`).
2.  **RoleBinding:** SA ini diikat dengan *Role* yang hanya mengizinkan aksi `patch/update` pada *resource* `Deployment` di *namespace* target (`dev` atau `staging`).
3.  **KUBE\_TOKEN:** Kubernetes secara otomatis membuat *Secret* yang berisi **Token JWT** untuk SA tersebut. Token inilah yang harus disimpan sebagai **Drone Secret** (misalnya, `KUBE_TOKEN_DEV` dan `KUBE_TOKEN_STAGING`).
4.  **Otoriasi:** *Plugin* `drone-kubectl` menggunakan token ini untuk membuktikan identitasnya kepada Kubernetes API Server, dan API Server kemudian memverifikasi izin token tersebut melalui RBAC.

### 2\. Implementasi Deployment di `.drone.yml` (GitLab Flow)

Untuk memisahkan *deployment* ke `dev` dan `staging`, kita menggunakan dua *steps* berbeda dengan kondisi `when: branch:` yang berbeda, tetapi keduanya menggunakan *plugin* `drone-kubectl`.

#### Skenario A: Deployment ke Lingkungan Development (Branch `main`)

*Tujuan: Otomatis, target **`namespace: dev`***

```yaml
- name: deploy-ke-dev
  image: lalk/drone-kubectl:latest # Atau image kubectl lain
  settings:
    # 1. Token dari Secret Drone CI (Harus memiliki RoleBinding ke namespace 'dev')
    token: { from_secret: KUBE_TOKEN_DEV } 
    # 2. Perintah Deployment Kritis: Mengubah image tag.
    commands:
      # Mengganti image tag Deployment dengan COMMIT_SHA terbaru
      - kubectl set image deployment/nama-deployment-dev nama-container=harbor.projek1.id/repo:{$DRONE_COMMIT_SHA:0:8} -n dev
  when:
    # Hanya berjalan saat push/merge terjadi di branch 'main'
    branch: [ main ] 
    status: [ success ] # Hanya jika semua tahap sebelumnya (Test, Scan) sukses
```

#### Skenario B: Deployment ke Lingkungan Staging (Branch `staging`)

*Tujuan: Manual, target **`namespace: staging`** (Sebagai *Quality Gate* tambahan)*

```yaml
- name: deploy-ke-staging
  image: lalk/drone-kubectl:latest
  settings:
    # 1. Token dari Secret Drone CI (Harus memiliki RoleBinding ke namespace 'staging')
    token: { from_secret: KUBE_TOKEN_STAGING } 
    # 2. Perintah Deployment Kritis:
    commands:
      - kubectl set image deployment/nama-deployment-staging nama-container=harbor.projek1.id/repo:{$DRONE_COMMIT_SHA:0:8} -n staging
  when:
    # Hanya berjalan saat push/merge terjadi di branch 'staging'
    branch: [ staging ]
    trigger: manual # MEMBUTUHKAN PERSETUJUAN MANUAL
```

### Kesimpulan Kritis

Tahap Deployment adalah validasi akhir dari *workflow*. Mahasiswa harus memastikan bahwa:

1.  Mereka menggunakan **`KUBE_TOKEN` yang berbeda** untuk setiap lingkungan, merefleksikan izin yang berbeda (*Least Privilege*).
2.  Perintah `kubectl set image` harus merujuk pada `COMMIT_SHA` yang sama yang berhasil di-*scan* pada **Tahap 4 (Security Scan)**, memastikan konsistensi dan keamanan.

---

# Bagian III: Penyiapan Lingkungan dan Otentikasi Lanjutan (Lab Prasyarat Kritis) 🛡️

## 🛡️ III.A. Membuat Multi-Namespace (Pemisahan Lingkungan)

Tujuan utama dari langkah ini adalah untuk mencapai **isolasi logis** antara lingkungan **Development** dan **Staging** dalam satu *cluster* Kubernetes. Isolasi ini mencegah *resource* lingkungan *development* mengganggu *resource* *staging*, dan sebaliknya.

### 1\. Tujuan Pemisahan Namespace

| Namespace | Mewakili Lingkungan | Peran dalam CI/CD |
| :--- | :--- | :--- |
| **`dev`** | **Development** | Tempat *testing* cepat dan otomatis (Deployment pemicu dari *branch* `develop`/`main`). |
| **`staging`** | **Staging/QA** | Tempat pengujian fungsionalitas dan performa akhir (Deployment pemicu dari *branch* `staging`, seringkali **Manual**). |

### 2\. Langkah-langkah Pembuatan Namespace

Mahasiswa harus menjalankan perintah ini langsung dari terminal di Vagrant VM mereka (tempat `kubectl` terkonfigurasi).

1.  **Membuat Namespace Development (`dev`):**
    Perintah ini menciptakan batas logis untuk semua *resource* terkait pengembangan.

    ```bash
    kubectl create namespace dev
    ```

2.  **Membuat Namespace Staging (`staging`):**
    Perintah ini menciptakan batas logis untuk lingkungan yang menyerupai produksi.

    ```bash
    kubectl create namespace staging
    ```

### 3\. Verifikasi Namespace

Setelah pembuatan, mahasiswa harus memverifikasi bahwa kedua *namespace* tersebut telah berhasil dibuat dan aktif di *cluster*.

```bash
kubectl get namespaces
```

**Output yang Diharapkan:**

```
NAME              STATUS   AGE
default           Active   ...
kube-system       Active   ...
kube-public       Active   ...
dev               Active   <sebentar>
staging           Active   <sebentar>
```

### 4\. Konsep Kritis: Memanfaatkan Namespace

Setiap perintah `kubectl` selanjutnya yang terkait dengan Deployment, Service, atau ConfigMap untuk aplikasi harus secara eksplisit menyertakan *flag* **`-n`** atau **`--namespace`** untuk menargetkan lingkungan yang benar.

  * **Contoh:** Untuk melihat *Pod* di lingkungan *Staging*:
    ```bash
    kubectl get pods -n staging
    ```

Langkah ini memastikan *resource* Dev dan Staging benar-benar terpisah dan siap untuk penerapan kontrol akses (RBAC) di langkah selanjutnya.

---

## 🛡️ III.B. Konfigurasi RBAC Environment (Least Privilege)

Tujuan utama konfigurasi ini adalah memberikan otorisasi kepada **satu** *Service Account* (SA), yaitu `drone-deployer`, untuk melakukan operasi **Deployment Update** di **dua** *namespace* yang berbeda (`dev` dan `staging`).

### 1\. Prasyarat: Komponen Dasar RBAC

Kita asumsikan komponen berikut sudah ada dari sesi *setup* awal:

  * **Service Account:** `drone-deployer` (umumnya berada di *namespace* `dev` atau `kube-system`).
  * **ClusterRole:** `drone-updater` atau serupa, yang mendefinisikan izin untuk `get`, `list`, `patch`, dan `update` pada *resource* `deployments`, `services`, dan `pods`.

### 2\. Konfigurasi RoleBinding untuk Multi-Namespace

Untuk memberikan akses ke *namespace* kedua (`staging`), kita perlu membuat `RoleBinding` baru. Peran SA (Subjek) diikat ke `ClusterRole` (Peran) di dalam *namespace* yang berbeda (*staging*).

#### A. RoleBinding di Namespace `dev` (Existing/Verification)

Pastikan sudah ada ikatan untuk lingkungan *development*.

```bash
# Contoh verifikasi RoleBinding di namespace dev
kubectl get rolebinding -n dev
```

#### B. Membuat RoleBinding di Namespace `staging` (New Configuration)

Buat *file* YAML (`staging-rolebinding.yaml`) yang mengikat SA `drone-deployer` ke `ClusterRole/drone-updater` di *namespace* `staging`.

```yaml
# staging-rolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: drone-deployer-staging-binding
  namespace: staging # <--- RoleBinding ini berlaku di namespace STAGING
subjects:
- kind: ServiceAccount
  name: drone-deployer
  namespace: dev # <--- SA ini berada di namespace DEV
roleRef:
  kind: ClusterRole
  name: drone-updater # <--- Izin yang diberikan (update deployments)
  apiGroup: rbac.authorization.k8s.io
```

**Instruksi Penerapan:**

```bash
kubectl apply -f staging-rolebinding.yaml
```

### 3\. Ekstraksi Token Kritis

Setelah `RoleBinding` berhasil dibuat, `KUBE_TOKEN` yang terkait dengan `ServiceAccount/drone-deployer` secara otomatis mendapatkan otoritas untuk berinteraksi dengan **kedua *namespace*** (`dev` dan `staging`).

Mahasiswa harus mengekstrak token ini untuk disimpan di Drone CI *Secrets*.

```bash
# Perintah untuk mendapatkan token dari Service Account
SA_SECRET_NAME=$(kubectl get sa drone-deployer -n dev -o=jsonpath='{.secrets[0].name}')
KUBE_TOKEN=$(kubectl get secret $SA_SECRET_NAME -n dev -o=jsonpath='{.data.token}' | base64 -d)

echo "KUBE_TOKEN Anda adalah: $KUBE_TOKEN"
```

> **Catatan Kritis:** Token ini harus disimpan sebagai **Drone Secret** (misalnya, **`KUBE_TOKEN_DEPLOY`**) dan akan digunakan di Tahap Deployment (Bagian II.5) untuk berotentikasi ke kedua lingkungan.

---


## 🛡️ III.C. Otentikasi Registry Privat di K8s (ImagePullSecret) 🔐

Ketika *Deployment* di Kubernetes merujuk pada *image* yang disimpan di *registry* privat (seperti Harbor) atau *repository* privat di Docker Hub, Kubernetes memerlukan kredensial untuk melakukan *image pull*. Kredensial ini disimpan dalam objek Kubernetes yang disebut **ImagePullSecret**.

### 1\. Konsep ImagePullSecret

  * **Tujuan:** Menyimpan kredensial *login* Docker (*username* dan *password*/token) dalam format yang dienkripsi base64.
  * **Tipe Secret:** Harus berjenis **`kubernetes.io/dockerconfigjson`**.
  * **Peran Kritis:** *Secret* ini harus dibuat di **setiap *namespace*** yang membutuhkan akses *image* tersebut (`dev` dan `staging`).

### 2\. Langkah Pembuatan ImagePullSecret (Contoh Harbor)

Kita akan menggunakan kredensial **Robot Account** Harbor yang sama dengan yang digunakan oleh Drone CI.

1.  **Ambil Kredensial:** Dapatkan:

      * *Docker Server*: `harbor.projek1.id` (atau IP Anda)
      * *Username*: `HARBOR_ROBOT_USERNAME`
      * *Password*: `HARBOR_ROBOT_TOKEN`

2.  **Perintah Pembuatan Secret:** Gunakan `kubectl create secret docker-registry` karena secara otomatis menangani enkripsi base64 dan pemformatan `.dockerconfigjson`.

      * **Untuk `namespace: dev`:**

        ```bash
        kubectl create secret docker-registry harbor-pull-secret \
          --docker-server=harbor.projek1.id \
          --docker-username=<HARBOR_ROBOT_USERNAME> \
          --docker-password=<HARBOR_ROBOT_TOKEN> \
          --namespace=dev
        ```

      * **Untuk `namespace: staging`:**

        ```bash
        kubectl create secret docker-registry harbor-pull-secret \
          --docker-server=harbor.projek1.id \
          --docker-username=<HARBOR_ROBOT_USERNAME> \
          --docker-password=<HARBOR_ROBOT_TOKEN> \
          --namespace=staging
        ```

### 3\. Konfigurasi ImagePullSecret untuk Docker Hub (Contoh Tambahan)

Jika *registry* yang digunakan adalah **Docker Hub** (dengan *repository* privat), prosesnya sama, hanya saja parameter *server*-nya berbeda:

| Parameter | Nilai untuk Docker Hub |
| :--- | :--- |
| **`--docker-server`** | `https://index.docker.io/v1/` atau `docker.io` |
| **`--docker-username`** | *Username* Docker Hub Anda |
| **`--docker-password`** | *Access Token* Docker Hub Anda |

  * **Perintah Contoh (Docker Hub):**

    ```bash
    kubectl create secret docker-registry dockerhub-pull-secret \
      --docker-server=docker.io \
      --docker-username=<DOCKER_USERNAME> \
      --docker-password=<DOCKER_ACCESS_TOKEN> \
      --namespace=staging
    ```

### 4\. Implementasi pada Deployment YAML 📑

Langkah terakhir yang sangat penting adalah memastikan *resource Deployment* Kubernetes merujuk pada *secret* yang baru dibuat. Ini harus ditambahkan di bawah spesifikasi *Pod* di **Deployment Manifest** Anda.

*Contoh Fragmen `deployment.yaml`:*

```yaml
# ... (Bagian deployment/replicas/selector) ...
spec:
  template:
    spec:
      containers:
        - name: web-container
          # Image harus dari registry privat Anda
          image: harbor.projek1.id/projek1/projek1-deployment:latest 
          # ...
      # Kritis: Merujuk ke ImagePullSecret
      imagePullSecrets:
        - name: harbor-pull-secret 
```

Jika langkah ini terlewatkan, *Pod* yang di-*deploy* oleh Drone CI akan masuk ke status **`ImagePullBackOff`**, karena Kubernetes tidak memiliki otorisasi untuk menarik *image* dari *registry* privat.

---


# Bagian IV: Implementasi dan Challenge Praktis: GitLab Flow 🚀

Tantangan akhir untuk menguji semua konsep:

| No. | Topik | Tujuan Implementasi |
| :--- | :--- | :--- |
| **IV.A** | **Implementasi CI di `develop`** | *Pipeline* berjalan otomatis saat *push* ke *branch* `develop`, melakukan Build, Test, Scan, dan Deploy ke *namespace* **`dev`**. |
| **IV.B** | **Implementasi CD ke `staging`** | *Pipeline* berjalan **MANUAL** (*trigger: manual*) saat *push* ke *branch* `staging`, dan menargetkan *namespace* **`staging`**. |
| **IV.C** | **Verifikasi Otentikasi** | Memastikan *Pod* di *namespace* `staging` berhasil di-*deploy* **HANYA** karena adanya *ImagePullSecret* yang dikonfigurasi di langkah III.C. |

---

## 🛡️ IV.A. Implementasi CI di `develop` (Otomatis ke `dev`)

### 1\. Struktur Kontrol Alur

Semua langkah di bawah ini akan menggunakan kondisi `when:` untuk memastikan mereka hanya berjalan pada *branch* `develop` dan hanya jika *step* sebelumnya berhasil (`status: [success]`).

| Aksi Kritis | Kondisi `when:` di `.drone.yml` |
| :--- | :--- |
| **Pemicu** | `branch: [ develop ]` |
| **Keberhasilan** | `status: [ success ]` |

-----

### 2\. Stage: Package & Publish (Dukungan Dual Registry) 📦

*Step* ini membuat *image* Docker dan mendorongnya ke *registry*. Kredensial rahasia (`secret`) harus digunakan untuk otentikasi.

#### Opsi 1: Registry Privat (Harbor)

```yaml
- name: publish-to-harbor
  image: plugins/docker:latest
  settings:
    # Target Harbor Registry
    repo: harbor.projek1.id/projek1/projek1-deployment 
    tags: [ ${DRONE_COMMIT_SHA:0:8}, latest ] 
    # Menggunakan Robot Account Secret
    username: { from_secret: HARBOR_ROBOT_USERNAME } 
    password: { from_secret: HARBOR_ROBOT_TOKEN } 
  when:
    branch: [ develop ]
```

#### Opsi 2: Docker Hub (Repository Privat)

Jika mahasiswa menggunakan Docker Hub dengan *repository* privat, konfigurasi hanya perlu menyesuaikan `repo` dan *secrets* yang digunakan.

```yaml
- name: publish-to-dockerhub
  image: plugins/docker:latest
  settings:
    # Target Docker Hub
    repo: docker.io/nama_user/projek1-deployment 
    tags: [ ${DRONE_COMMIT_SHA:0:8}, latest ] 
    # Menggunakan Docker Hub Access Token Secret
    username: { from_secret: DOCKER_USERNAME } 
    password: { from_secret: DOCKER_ACCESS_TOKEN } 
  when:
    branch: [ develop ]
```

-----

### 3\. Stage: Security Scan (Trivy) 🛡️

*Step* ini memindai *image* yang baru saja di-*push*. Karena *image* berada di *registry* privat (Harbor) atau semi-privat (Docker Hub), Trivy memerlukan kredensial untuk menarik (*pull*) *image* tersebut untuk di-*scan*.

#### Konfigurasi Trivy (Harbor/Docker Hub)

```yaml
- name: security-scan-trivy
  image: aquasec/trivy:latest
  environment:
    # Kredensial Trivy sama dengan kredensial Publish
    # Ganti variabel ini sesuai dengan registry yang digunakan
    TRIVY_USERNAME: { from_secret: HARBOR_ROBOT_USERNAME / DOCKER_USERNAME } 
    TRIVY_PASSWORD: { from_secret: HARBOR_ROBOT_TOKEN / DOCKER_ACCESS_TOKEN }
  commands:
    # Perintah Kritis: Menggunakan image tag SHA terbaru
    - IMAGE_TAG_SHA=${DRONE_COMMIT_SHA:0:8}
    # Ganti URL Registry sesuai pilihan mahasiswa
    - IMAGE_TO_SCAN=harbor.projek1.id/projek1/projek1-deployment:$IMAGE_TAG_SHA 
    
    # --exit-code 1 memblokir pipeline jika ditemukan kerentanan HIGH/CRITICAL
    - trivy image --exit-code 1 --severity HIGH,CRITICAL --ignore-unfixed $IMAGE_TO_SCAN
  when:
    branch: [ develop ]
    status: [ success ] # Hanya jalan jika publish sukses
```

-----

### 4\. Stage: Deployment ke `dev` 🚀

Hanya jika *Security Scan* berhasil (`status: [success]`), *pipeline* melanjutkan ke *deployment* di *namespace* `dev`.

```yaml
- name: deploy-ke-dev-otomatis
  image: lalk/drone-kubectl:latest
  settings:
    kubernetes_server: https://192.168.56.10:6443 
    # Menggunakan KUBE_TOKEN (RBAC) yang telah disiapkan di Bagian III.B
    token: { from_secret: KUBE_TOKEN_DEPLOY } 
    commands:
      - IMAGE_TAG=$(echo ${DRONE_COMMIT_SHA:0:8})
      # Kritis: Update image tag dan TEPAT di namespace DEV
      - kubectl set image deployment/projek1-deployment-dev web-container=harbor.projek1.id/projek1/projek1-deployment:$IMAGE_TAG -n dev
  when:
    branch: [ develop ] 
    status: [ success ] # Hanya jalan jika scan sukses
```

**Verifikasi Kritis Tahap ini:**

Mahasiswa harus memastikan bahwa setiap *push* ke `develop`:

1.  Berhasil **Build** dan **Publish**.
2.  Berhasil di-*scan* oleh **Trivy** (dan gagal jika ada *vulnerability*).
3.  Secara otomatis meng-*update* *Deployment* di **`namespace: dev`**.

---

## 🛡️ IV.B. Implementasi CD ke `staging` (Manual ke `staging`)

Tujuan: Mengkonfigurasi *pipeline* untuk *branch* `staging` agar melalui **Build, Scan, dan Publish** secara otomatis, tetapi proses **Deployment** dihentikan dan memerlukan *trigger* manual.

### 1\. Struktur Kontrol Alur Kritis

  * **Pemicu:** `branch: [ staging ]`
  * **Aksi Manual:** **`trigger: manual`** (Hanya diterapkan pada *step* Deployment).

### 2\. Stage: Publish & Scan (Otomatis) 📦

*Step* **Build, Publish, dan Scan** harus berjalan otomatis di *branch* `staging` (mirip dengan `develop`), memastikan *image* yang siap rilis sudah aman sebelum diminta untuk di-*deploy* secara manual.

#### Opsi 1: Registry Privat (Harbor)

```yaml
# Step 1: Publish Image ke Harbor
- name: publish-to-harbor
  image: plugins/docker:latest
  settings:
    repo: harbor.projek1.id/projek1/projek1-deployment 
    tags: [ ${DRONE_COMMIT_SHA:0:8}, staging ] 
    username: { from_secret: HARBOR_ROBOT_USERNAME } 
    password: { from_secret: HARBOR_ROBOT_TOKEN } 
  when:
    branch: [ staging ] # Dipicu oleh branch staging

# Step 2: Security Scan (Trivy)
- name: security-scan-trivy
  image: aquasec/trivy:latest
  environment:
    TRIVY_USERNAME: { from_secret: HARBOR_ROBOT_USERNAME } 
    TRIVY_PASSWORD: { from_secret: HARBOR_ROBOT_TOKEN }
  commands:
    - IMAGE_TO_SCAN=harbor.projek1.id/projek1/projek1-deployment:${DRONE_COMMIT_SHA:0:8}
    - trivy image --exit-code 1 --severity HIGH,CRITICAL --ignore-unfixed $IMAGE_TO_SCAN
  when:
    branch: [ staging ] 
    status: [ success ]
```

#### Opsi 2: Docker Hub

Jika menggunakan Docker Hub, ubah `repo` dan *secrets* di *step* **Publish** (Step 1) dan *Environment Variables* di *step* **Scan** (Step 2) menjadi kredensial Docker Hub (`DOCKER_USERNAME`, `DOCKER_ACCESS_TOKEN`).

-----

### 3\. Stage: CD - Deployment ke `staging` (Manual) 🛑

*Step* ini adalah kunci tantangan. *Step* **Deployment** harus menunggu persetujuan manusia, dan harus menargetkan *namespace* **`staging`**.

```yaml
- name: deploy-ke-staging-manual
  image: lalk/drone-kubectl:latest
  settings:
    kubernetes_server: https://192.168.56.10:6443 
    token: { from_secret: KUBE_TOKEN_DEPLOY } # Token yang memiliki RBAC ke staging
    commands:
      - IMAGE_TAG=$(echo ${DRONE_COMMIT_SHA:0:8})
      # Kritis: Update image tag dan TEPAT di namespace STAGING
      - kubectl set image deployment/projek1-deployment-staging web-container=harbor.projek1.id/projek1/projek1-deployment:$IMAGE_TAG -n staging
      # Jika menggunakan Docker Hub, ganti harbor.projek1.id dengan docker.io/nama_user
  when:
    branch: [ staging ] 
    status: [ success ] 
    # KUNCI TANTANGAN: Mengubah trigger menjadi manual
    trigger: manual 
```

### Verifikasi Kritis Tahap ini:

1.  **Workflow Control:** Mahasiswa harus membuktikan bahwa setelah *push* ke `staging`, *pipeline* berjalan melewati **Scan** tetapi berhenti di *step* **deploy-ke-staging-manual** dengan status **'Pending'** atau **'Waiting'**.
2.  **Aksi Manual:** Mereka harus menekan tombol **'Approve'** di antarmuka Drone CI untuk melanjutkan *deployment*.
3.  **Targeting:** Setelah sukses, mereka harus memverifikasi bahwa *image* baru berjalan di **`namespace: staging`** (misalnya, `kubectl get pods -n staging`).

---

## 🛡️ IV.C. Verifikasi Otentikasi (*ImagePullSecret*)

Tujuan dari tahap ini adalah membuktikan secara empiris bahwa *Deployment* di Kubernetes berhasil karena adanya *ImagePullSecret*, dan bukan karena *image* diakses secara anonim (publik).

### 1\. Prasyarat Verifikasi Kritis

1.  *Image* yang digunakan dalam *Deployment* harus berada di **Repository Privat** (baik di Harbor maupun Docker Hub).
2.  *Deployment Manifest* di *namespace* `staging` telah merujuk pada *ImagePullSecret* (`harbor-pull-secret` atau `dockerhub-pull-secret`).

### 2\. Skenario Verifikasi (Pembuktian)

Mahasiswa harus menjalankan dua skenario untuk membuktikan pentingnya *ImagePullSecret*:

| Skenario | Aksi | Hasil Kritis yang Diharapkan |
| :--- | :--- | :--- |
| **Skenario 1: Sukses (Kondisi Normal)** | *Deployment* di-*trigger* (manual) di *namespace* `staging` dengan *Deployment Manifest* **MERUJUK** pada `ImagePullSecret`. | *Pod* mencapai status **`Running`** dalam hitungan detik. Verifikasi status *Pod* tidak menunjukkan error **`ImagePullBackOff`**. |
| **Skenario 2: Gagal (Kondisi Pembuktian)** | Hapus referensi `ImagePullSecret` dari *Deployment Manifest* dan *update* *Deployment* di *namespace* `staging`. | *Pod* akan gagal dengan status **`ImagePullBackOff`** atau **`ErrImagePull`**. |

### 3\. Langkah-Langkah Verifikasi dan Debugging

Mahasiswa harus memverifikasi status *Pod* setelah *Deployment* sukses (Skenario 1) menggunakan *flag* `-n staging`.

#### A. Verifikasi Status Pod (Sukses)

Pastikan *Deployment* berhasil dan *Pod* mencapai status `Running`.

```bash
kubectl get pods -n staging
# Output yang diharapkan:
# NAME                         READY   STATUS    RESTARTS   AGE
# nama-deployment-staging-...   1/1     Running   0          <sebentar>
```

#### B. Debugging Kritis (*ImagePullBackOff*)

Jika terjadi kegagalan (Skenario 2), *Pod* akan menampilkan status `ImagePullBackOff`. Mahasiswa harus menggunakan perintah `describe` untuk melihat alasan kegagalan:

```bash
kubectl describe pod <nama-pod> -n staging
```

**Verifikasi Kritis:** Di bagian *Events*, mahasiswa akan menemukan pesan serupa:

```
Events:
  Type     Reason          Age    From               Message
  ----     ------          ----   ----               -------
  ...
  Warning  FailedToPull    10s    kubelet            Failed to pull image "harbor.projek1.id/repo:sha"
  Warning  ErrImagePull    10s    kubelet            Failed to pull image "harbor.projek1.id/repo:sha": rpc error: code = Unknown desc = error response from daemon: unauthorized: access to the requested resource is not authorized
  Warning  ImagePullBackOff 1s    kubelet            Back-off pulling image "harbor.projek1.id/repo:sha"
```

Jika error yang muncul adalah **`unauthorized`** atau **`access denied`**, itu membuktikan bahwa:

1.  *Repository* adalah privat.
2.  Kubernetes mencoba menarik *image* secara anonim.
3.  Konfigurasi `ImagePullSecret` pada *Deployment Manifest* **hilang atau salah**.

### 4\. Konfigurasi ImagePullSecret (Pilihan Registry)

Mahasiswa harus memastikan *Deployment Manifest* merujuk ke *secret* yang sesuai dengan pilihan *registry* mereka:

| Pilihan Registry | Nama Secret yang Dibuat |
| :--- | :--- |
| **Harbor** | `harbor-pull-secret` (Dibuat dari `harbor.projek1.id`) |
| **Docker Hub** | `dockerhub-pull-secret` (Dibuat dari `docker.io`) |

**Penting:** Nama *secret* dalam *Deployment Manifest* harus sama persis dengan nama *secret* yang dibuat menggunakan `kubectl create secret docker-registry...` di *namespace* yang sama.

---