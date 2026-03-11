# Modul End-to-End Pipeline: Harbor (Lokal)

## ⚙️ 1. Prasyarat & Penyiapan Awal (Host/VM)

### A. Verifikasi Akses Semua Layanan 🌐

Mahasiswa harus memastikan setiap komponen infrastruktur yang sudah dibangun di dalam Vagrant VM berfungsi dan dapat diakses dari **Host Machine** menggunakan IP **`192.168.56.10`**.

| Layanan | Alamat Akses (Host) | Status yang Diharapkan |
| :--- | :--- | :--- |
| **Gitea** (Git Server) | `http://192.168.56.10:3000` | Halaman *login* Gitea muncul. |
| **Harbor** (Registry) | `https://192.168.56.10` | Halaman *login* Harbor muncul (mungkin muncul peringatan sertifikat). |
| **Drone CI** (CI/CD) | `http://192.168.56.10:8000` | Halaman *dashboard* Drone CI muncul (setelah *login* via Gitea). |
| **Kubernetes** | `kubectl get nodes` (di VM) | Semua *Node* di *cluster* (misalnya `1`) berstatus **`Ready`**. |

-----

### B. Persiapan Kode dan Repository di Gitea 📂

Mahasiswa akan menyiapkan aplikasi sampel dan mendorongnya ke *repository* di Gitea.

1.  **Buat Repository di Gitea:**
      * *Login* ke Gitea dan buat *repository* baru (misalnya **`projek1-deployment`**).
2.  **Clone Repository:**
      * *Clone* *repository* ke **Host Machine** (atau di dalam VM jika *developing* di sana).
    <!-- end list -->
    ```bash
    # Jika menggunakan SSH, pastikan menggunakan port 222
    git clone ssh://git@192.168.56.10:222/admin/projek1-deployment.git
    cd projek1-deployment
    ```
3.  **Buat Aplikasi Sederhana:**
      * Buat *file* `app.py` (misalnya Flask sederhana) dan `Dockerfile`.
4.  **Buat Manifest Kubernetes Awal:**
      * Buat direktori `deploy/` dan letakkan *file* `deployment.yaml` dan `service.yaml` di dalamnya. Pastikan *image* di `deployment.yaml` menggunakan nama *full* **Harbor** dan *tag* sementara (misalnya `harbor.projek1.id/projek1/projek1-deployment:initial`).
5.  **Initial Push:**
      * *Commit* semua *file* (`app.py`, `Dockerfile`, `deploy/`) dan *push* ke Gitea.
    <!-- end list -->
    ```bash
    git add .
    git commit -m "Initial commit: Application code and manifests"
    git push origin main
    ```

-----

### C. Konfigurasi Kredensial Rahasia (Drone Secrets) 🔒

Semua token sensitif harus disimpan sebagai **Secrets** di *dashboard* Drone CI untuk digunakan dalam *pipeline*.

1.  **Dapatkan Token:**
      * **Harbor Token:** Dapatkan **Token Rahasia** dari **Robot Account** Harbor yang sudah dibuat.
      * **Kube Token:** Dapatkan **Service Account Token** yang sudah Anda ekstrak dan dekode (nilai dari variabel `$DRONE_TOKEN` di langkah sebelumnya).
2.  **Buat Secrets di Drone CI:**
      * *Login* ke Drone CI (`http://192.168.56.10:8000`).
      * Aktifkan *repository* **`projek1-deployment`** jika belum.
      * Masuk ke **Settings** \> **Secrets** di *repository* tersebut.
      * **Tambahkan 3 Secrets:**

| Nama Secret | Nilai (Value) | Deskripsi |
| :--- | :--- | :--- |
| **`HARBOR_ROBOT_USERNAME`** | `robot$nama-robot` | Nama **Robot Account** Harbor. |
| **`HARBOR_ROBOT_TOKEN`** | *string-token-rahasia* | Token **Robot Account** Harbor. |
| **`KUBE_TOKEN`** | *string-token-sa-k8s* | Token **Service Account** Kubernetes (`drone-deployer`). |

Semua *secrets* ini akan dipanggil dalam *file* `.drone.yml` Anda di bagian berikutnya.

---

## 📝 2. Implementasi Pipeline (`.drone.yml`)

Mahasiswa akan membuat *file* ini di direktori akar *repository* **`projek1-deployment`** (yang telah di-*clone* dari Gitea).

### A. Struktur File dan Tiga Langkah Utama

*File* ini akan berjalan setiap kali ada *push* ke *branch* `main`.

```yaml
kind: pipeline
type: docker
name: ci-cd-harbor-deploy

workspace:
  base: /go
  path: src/projek1-deployment

steps:
# 1. STEP BUILD & PUSH KE HARBOR
- name: build-and-push-harbor
  image: plugins/docker:latest
  environment:
    # Set INSECURE=true untuk mengabaikan masalah SSL/TLS (jika belum diatasi di Runner)
    # Ini WAJIB jika sertifikat Harbor adalah self-signed
    DOCKER_OPTS: --insecure-registry harbor.projek1.id
  settings:
    # Gunakan FQDN Harbor yang sudah diset di VM
    repo: harbor.projek1.id/projek1/projek1-deployment 
    # Tagging dinamis menggunakan 8 karakter pertama dari Commit SHA (variabel bawaan Drone)
    tags: [ ${DRONE_COMMIT_SHA:0:8}, latest ] 
    
    # Kredensial Otentikasi Harbor (diambil dari Drone Secrets)
    username:
      from_secret: HARBOR_ROBOT_USERNAME 
    password:
      from_secret: HARBOR_ROBOT_TOKEN 
  when:
    branch: [ main ]

# 2. STEP DEPLOY KE KUBERNETES
- name: deploy-ke-kubernetes
  image: lalk/drone-kubectl:latest # Plugin untuk berinteraksi dengan K8s
  settings:
    # Konfigurasi Akses K8s API Server (Ganti IP jika K8s API Server berada di tempat lain)
    kubernetes_server: https://192.168.56.10:6443 
    # Otentikasi: Menggunakan Token Service Account K8s (diambil dari Drone Secrets)
    kubernetes_token:
      from_secret: KUBE_TOKEN
      
    # Perintah Deployment Kritis: Mengganti image tag secara dinamis
    script:
      # Set tag image baru menggunakan variabel SHA
      - IMAGE_TAG=$(echo ${DRONE_COMMIT_SHA:0:8})
      
      # Perintah kubectl set image:
      # - Memperbarui Deployment 'projek1-deployment'
      # - Mengganti image container 'web-container'
      # - Dengan image dari Harbor dan tag yang baru dibuat
      - kubectl set image deployment/projek1-deployment web-container=harbor.projek1.id/projek1/projek1-deployment:$IMAGE_TAG -n dev
  when:
    branch: [ main ]
```

-----

### B. Step *Build and Push* (Detail Penggunaan Secrets)

  * **Plugin:** Menggunakan `plugins/docker:latest`. Plugin ini bertindak sebagai *client* Docker dan memiliki kemampuan otentikasi.
  * **Otentikasi Aman:** *Secrets* **`HARBOR_ROBOT_USERNAME`** dan **`HARBOR_ROBOT_TOKEN`** digunakan untuk *login* ke Harbor Registry. Nilai asli token tidak pernah terekspos di *file* Git atau di *build log*.
  * **Tagging Dinamis:** `tags: [ ${DRONE_COMMIT_SHA:0:8} ]` memastikan bahwa setiap *push* yang sukses menghasilkan *image* dengan *tag* unik yang didasarkan pada *commit* kode.

### C. Step *Deploy* (Detail Deployment Dinamis)

  * **Plugin:** Menggunakan `lalk/drone-kubectl:latest` yang sudah dilengkapi utilitas `kubectl`.
  * **Otentikasi K8s:** `kubernetes_token: from_secret: KUBE_TOKEN` adalah kunci. Token Service Account yang sudah divalidasi digunakan untuk otorisasi *deployment*.
  * **Perintah Dinamis (`kubectl set image`):**
      * `kubectl set image deployment/projek1-deployment web-container=harbor.projek1.id/projek1/projek1-deployment:$IMAGE_TAG -n dev`
      * Perintah ini adalah cara paling cepat untuk memperbarui *image tag* di Deployment yang sudah ada. Drone akan menyuntikkan *tag* yang baru di-*push* ke Harbor, menyebabkan Kubernetes melakukan **Rolling Update** pada *Deployment* tersebut.

Setelah *file* ini ditambahkan dan di-*push* ke Gitea, *pipeline* akan otomatis terpicu.

---

Tentu, Bapak Arif. Langkah **Eksekusi dan Verifikasi Kritis** ini adalah bagian terpenting dari modul, karena membuktikan bahwa seluruh rantai CI/CD berfungsi sesuai harapan.

Berikut adalah langkah-langkah detail yang harus diikuti mahasiswa untuk menjalankan *pipeline* dan memvalidasi hasilnya di semua komponen.

-----

## 🚀 3. Eksekusi dan Verifikasi

### A. Trigger Pipeline (Pemicuan) 📤

*Pipeline* di Drone CI dipicu secara otomatis oleh *webhook* dari Gitea.

1.  **Lakukan Perubahan Kode:** Mahasiswa harus melakukan perubahan kecil pada kode aplikasi (misalnya, mengubah pesan *output* di `app.py` dari `v1.0.0` menjadi `v1.0.1`) untuk memastikan *image* baru dibuat.
2.  **Commit dan Push Perubahan:**
    ```bash
    # Di dalam repository lokal 'projek1-deployment'
    git add .
    git commit -m "Feature: Update app version to v1.0.1"
    git push origin main
    ```
3.  **Verifikasi di Gitea:** Periksa tab **Webhooks** di *repository* Gitea. Pastikan Gitea mengirim *payload* *push* ke Drone CI dengan status **200 OK**.

-----

### B. Verifikasi di Drone CI (Build dan Log) ✅

Mahasiswa harus memantau proses *build* di *dashboard* Drone CI secara *real-time*.

1.  **Akses Dashboard Drone:** Buka `http://192.168.56.10:8000` dan navigasi ke *repository* **`projek1-deployment`**.
2.  **Periksa Status Build:** Pastikan *build* terbaru sedang berjalan dan akhirnya berstatus **SUCCESS**.
3.  **Audit Step `build-and-push-harbor`:**
      * Periksa *log* di *step* ini. Cari pesan yang mengindikasikan **Docker Login berhasil** (menggunakan kredensial Robot Account).
      * Pastikan *log* mencantumkan pesan **`Pushing image harbor.projek1.id/projek1/projek1-deployment:<commit-SHA>`** berhasil.
      * **Verifikasi SSL/TLS (Kritis):** Jika Anda menggunakan opsi `DOCKER_OPTS: --insecure-registry harbor.projek1.id`, pastikan *log* mencatat bahwa Docker mengabaikan masalah sertifikat dan *push* tetap sukses.
4.  **Audit Step `deploy-ke-kubernetes`:**
      * Periksa *log* di *step* ini. Cari perintah `kubectl set image...` yang dieksekusi.
      * Output yang diharapkan adalah: **`deployment.apps/projek1-deployment image updated`**. Ini memverifikasi bahwa `KUBE_TOKEN` berfungsi dan *Service Account* memiliki izin `update` ke Kubernetes.

-----

### C. Verifikasi di Harbor (Image Registry) 📦

Pastikan *pipeline* telah memenuhi tujuan pertamanya, yaitu mempublikasikan *image* baru.

1.  **Akses Harbor UI:** Buka `https://192.168.56.10` dan *login*.
2.  **Navigasi ke Proyek:** Buka **Project** \> **`projek1`** \> **Repositories**.
3.  **Cek Tag Baru:** Verifikasi bahwa *repository* **`projek1-deployment`** sekarang memiliki **dua** *tag*:
      * **`latest`** (image terbaru).
      * **`<commit-SHA>`** (tag unik 8 karakter dari *commit* terakhir).

-----

### D. Verifikasi di Kubernetes (Cluster Status) 🚢

Ini adalah verifikasi akhir, yang memastikan *deployment* sudah tayang. Mahasiswa harus menjalankan perintah `kubectl` di dalam VM.

1.  **Verifikasi Deployment Update:**
      * Periksa status *deployment* untuk melihat *image* mana yang sedang digunakan.
    <!-- end list -->
    ```bash
    kubectl describe deployment projek1-deployment -n dev
    ```
      * Di bagian **Containers** \> **Image**, pastikan URL *image* sudah diperbarui ke: **`harbor.projek1.id/projek1/projek1-deployment:<commit-SHA>`** yang baru.
2.  **Verifikasi Pod Baru:**
      * Pastikan Kubernetes telah berhasil melakukan *Rolling Update* dengan *Pod* yang baru.
    <!-- end list -->
    ```bash
    kubectl get pods -n dev
    ```
      * Pastikan *Pod* lama berstatus `Terminating` dan *Pod* baru sudah berstatus **`Running`**.
3.  **Verifikasi Aplikasi (End-User):**
      * Akses aplikasi melalui alamat *Service* atau *Ingress* yang sudah dikonfigurasi.
      * Pastikan *output* yang muncul adalah versi terbaru (**v1.0.1**).

Jika semua langkah ini berstatus sukses, *pipeline* CI/CD *end-to-end* Anda telah berhasil diimplementasikan.

---

# 🚀 Layout Modul End-to-End Pipeline: Docker Hub

Tentu, Bapak Arif. Kita akan mendetailkan langkah-langkah penyiapan awal untuk skenario **Docker Hub**, yang berfokus pada pergantian kredensial dari Harbor ke Docker Hub.

---

## ⚙️ 1. Prasyarat & Penyiapan Awal (Host/VM)

### A. Verifikasi Akses Layanan Inti 🌐

Langkah pertama adalah memastikan komponen inti yang tidak berubah (Gitea, Drone CI, Kubernetes) masih berfungsi dengan baik di Vagrant VM Anda (IP: `192.168.56.10`).

| Layanan | Alamat Akses (Host) | Tujuan Verifikasi |
| :--- | :--- | :--- |
| **Gitea** | `http://192.168.56.10:3000` | Memastikan *source code* tersedia. |
| **Drone CI** | `http://192.168.56.10:8000` | Memastikan *engine* CI/CD siap menerima *job*. |
| **Kubernetes** | `kubectl get pods -n dev` (di VM) | Memastikan *cluster* siap menerima *deployment* baru. |

---

### B. Persiapan Kode di Gitea 📂

Mahasiswa akan menggunakan *repository* yang sama, **`projek1-deployment`**, yang sudah ada di Gitea. Tidak ada perubahan besar pada kode aplikasi atau `Dockerfile` yang diperlukan, karena fokusnya adalah perubahan *registry*.

1.  **Repository Siap:** Pastikan *file* kode aplikasi (`app.py`), `Dockerfile`, dan *manifest* K8s (`deploy/`) sudah berada di *repository* Gitea.
2.  **Koreksi Manifest (Opsional):** Jika sebelumnya *file* `deployment.yaml` di Git secara eksplisit merujuk ke Harbor, ingatkan mahasiswa bahwa *pipeline* nanti akan melakukan *patch* untuk merujuk ke Docker Hub.

---

### C. Konfigurasi Kredensial Rahasia Docker Hub 🔒

Ini adalah langkah kritis. Kredensial Harbor harus dinonaktifkan dan diganti dengan kredensial Docker Hub untuk otentikasi *push*.

1.  **Dapatkan Kredensial Docker Hub:**
    * Mahasiswa harus memiliki akun Docker Hub dan **Access Token** (direkomendasikan, bukan *password* langsung) atau *username* dan *password* akun.

2.  **Modifikasi Secrets di Drone CI:**
    * *Login* ke Drone CI (`http://192.168.56.10:8000`).
    * Navigasi ke **Settings** > **Secrets** di *repository* **`projek1-deployment`**.

3.  **Nonaktifkan/Hapus Secrets Harbor:**
    * **Hapus** atau **Nonaktifkan** (*disable*) *Secrets*:
        * `HARBOR_ROBOT_USERNAME`
        * `HARBOR_ROBOT_TOKEN`
    *(Drone CI harus gagal jika mencoba menggunakan kredensial Harbor)*

4.  **Tambahkan Secrets Docker Hub:**
    * Tambahkan dua *Secrets* baru untuk otentikasi *push* ke Docker Hub:

| Nama Secret | Nilai (Value) | Deskripsi |
| :--- | :--- | :--- |
| **`DOCKER_USERNAME`** | *Username* Docker Hub Anda | *Username* akun Docker Hub. |
| **`DOCKER_PASSWORD`** | *Password* atau *Access Token* Docker Hub | Token untuk otentikasi *push*. |
| **`KUBE_TOKEN`** | *string-token-sa-k8s* | **TETAP DIGUNAKAN** (Kredensial K8s tidak berubah). |

Setelah langkah ini, *pipeline* Drone CI akan *fail* jika mencoba menggunakan kredensial Harbor, tetapi akan siap untuk *push* ke Docker Hub.
---

## 📝 2. Implementasi Pipeline (`.drone.yml` V2)

Mahasiswa akan mengganti isi *file* `.drone.yml` yang ada di *repository* Gitea dengan struktur berikut. Perhatikan bahwa konfigurasi **Docker Hub** jauh lebih sederhana karena tidak memerlukan pengaturan *insecure registry* (masalah SSL/TLS).

### A. Struktur File dan URL Docker Hub

```yaml
kind: pipeline
type: docker
name: ci-cd-dockerhub-deploy

workspace:
  base: /go
  path: src/projek1-deployment

steps:
# 1. STEP BUILD & PUSH KE DOCKER HUB
- name: build-and-push-dockerhub
  image: plugins/docker:latest
  settings:
    # 1. Image Naming: Menggunakan format Docker Hub (username/repo)
    # Ganti 'mydockerhubuser' dengan username Docker Hub yang sebenarnya
    repo: mydockerhubuser/projek1-deployment 
    # Tagging dinamis menggunakan commit SHA
    tags: [ ${DRONE_COMMIT_SHA:0:8}, latest ] 
    
    # 2. Kredensial Otentikasi Docker Hub (diambil dari Drone Secrets)
    username:
      from_secret: DOCKER_USERNAME 
    password:
      from_secret: DOCKER_PASSWORD 
    
    # Kritis: Tidak ada opsi 'insecure: true' atau DOCKER_OPTS
  when:
    branch: [ main ]

# 2. STEP DEPLOY KE KUBERNETES
- name: deploy-ke-kubernetes
  image: lalk/drone-kubectl:latest
  settings:
    # Kredensial K8s (Tidak Berubah, menggunakan token Service Account yang sama)
    kubernetes_server: https://192.168.56.10:6443 
    kubernetes_token:
      from_secret: KUBE_TOKEN
      
    # Perintah Deployment Kritis: Memperbarui URL Image ke Docker Hub
    script:
      # Set tag image baru menggunakan variabel SHA
      - IMAGE_TAG=$(echo ${DRONE_COMMIT_SHA:0:8})
      
      # Perintah kubectl set image:
      # - Mengganti image container 'web-container'
      # - Dengan image dari Docker Hub dan tag yang baru dibuat
      - kubectl set image deployment/projek1-deployment web-container=mydockerhubuser/projek1-deployment:$IMAGE_TAG -n dev
  when:
    branch: [ main ]
```

-----

### B. Step *Build and Push* (Docker Hub) 📦

  * **Perubahan Kritis:** Nilai pada kunci `repo` diubah dari FQDN Harbor menjadi **`mydockerhubuser/projek1-deployment`**.
  * **Otentikasi:** Kunci `username` dan `password` kini merujuk ke *Secrets* **`DOCKER_USERNAME`** dan **`DOCKER_PASSWORD`**. Ini memvalidasi kemampuan Drone CI untuk berganti otentikasi registri dengan cepat.
  * **Keamanan SSL:** Karena Docker Hub menggunakan sertifikat yang valid dan dipercayai secara publik, kita **TIDAK** perlu menambahkan opsi `DOCKER_OPTS: --insecure-registry` atau *flag* serupa.

### C. Step *Deploy* (Update Manifest) 🚢

  * **Kredensial K8s (Sama):** *Secrets* **`KUBE_TOKEN`** dan `kubernetes_server` **tidak berubah**. Ini menunjukkan bahwa otorisasi ke *cluster* bersifat independen dari *registry* mana *image* berasal.
  * **Perintah Dinamis:** Perintah `kubectl set image` diperbarui untuk mencerminkan URL *image* yang baru:
    ```bash
    kubectl set image deployment/projek1-deployment web-container=mydockerhubuser/projek1-deployment:$IMAGE_TAG -n dev
    ```
    *Kubernetes kini akan melakukan *image pull* dari Docker Hub.*

Setelah *file* `.drone.yml` baru ini di-*push* ke Gitea, *pipeline* akan otomatis beralih menggunakan Docker Hub.

---

## 🔎 3. Eksekusi dan Verifikasi Kritis (Docker Hub)

### A. Trigger Pipeline (Pemicuan) 📤

Sama seperti skenario sebelumnya, *pipeline* dipicu melalui *push* kode ke Gitea.

1.  **Lakukan Perubahan:** Lakukan perubahan kecil pada kode aplikasi atau dokumentasi (`README.md`) untuk memastikan ada *commit* baru.
2.  **Commit dan Push `.drone.yml` V2:** Pastikan *file* **`.drone.yml` V2 (yang merujuk ke Docker Hub)** sudah di-*commit* dan di-*push* ke Gitea.
    ```bash
    git add .drone.yml
    git commit -m "Config: Switch pipeline to use Docker Hub registry"
    git push origin main
    ```
3.  **Verifikasi di Gitea:** Konfirmasikan Gitea mengirim *webhook* ke Drone CI.

-----

### B. Verifikasi di Drone CI (Log) ✅

Perhatian utama di sini adalah memverifikasi **otentikasi ke Docker Hub** dan keberhasilan *deployment* ke K8s.

1.  **Akses Dashboard Drone:** Buka *dashboard* Drone CI dan pantau *build* terbaru.
2.  **Audit Step `build-and-push-dockerhub`:**
      * Periksa *log* di *step* ini. Cari pesan yang mengindikasikan **Docker Login berhasil** menggunakan kredensial **`DOCKER_USERNAME`**.
      * Pastikan *log* mencantumkan: **`Pushing image mydockerhubuser/projek1-deployment:<commit-SHA>`** berhasil dengan status `Pushed`.
3.  **Audit Step `deploy-ke-kubernetes`:**
      * Periksa *log* untuk memastikan perintah `kubectl set image` berhasil dieksekusi.
      * Output yang diharapkan adalah: **`deployment.apps/projek1-deployment image updated`**.

-----

### C. Verifikasi di Docker Hub (Registry Publik) 📦

Mahasiswa harus memverifikasi bahwa *image* berhasil dipublikasikan ke *registry* publik Docker Hub.

1.  **Akses Docker Hub:** Buka *web browser* dan navigasi ke halaman *repository* Anda di Docker Hub.
2.  **Cek Tag Baru:** Verifikasi bahwa **`Repository: mydockerhubuser/projek1-deployment`** sekarang memiliki *tag* baru yang sesuai dengan **`<commit-SHA>`** dari *commit* terakhir.

-----

### D. Verifikasi di Kubernetes (Cluster Status) 🚢

Langkah terakhir ini memverifikasi bahwa *cluster* berhasil menarik *image* dari sumber eksternal (Docker Hub).

1.  **Periksa Image di Deployment:** Jalankan perintah `kubectl` di Vagrant VM.
    ```bash
    kubectl describe deployment projek1-deployment -n dev
    ```
      * Di bagian **Containers** \> **Image**, pastikan URL *image* sudah diperbarui ke: **`mydockerhubuser/projek1-deployment:<commit-SHA>`** yang baru.
2.  **Verifikasi Image Pull:**
      * Jika *pull* berhasil, *Pod* akan berstatus **`Running`**.
      * Jika *pull* gagal (misalnya, jika *tag* tidak ada di Docker Hub), *Pod* akan berstatus **`ImagePullBackOff`**.
    <!-- end list -->
    ```bash
    kubectl get pods -n dev
    ```
3.  **Validasi Fungsional:** Akses aplikasi web melalui *Service* atau *Ingress* untuk memastikan *deployment* dari Docker Hub berjalan dengan baik.

Jika semua langkah ini sukses, mahasiswa telah berhasil menunjukkan fleksibilitas *pipeline* Drone CI dalam berpindah *registry* dari Harbor (Lokal, *Insecure*) ke Docker Hub (Publik, *Secure*).