# 😴 Pipeline Drone Bisa Jalan Sendiri Kok... Tinggal Push, Terus Tinggal Tidur - Goodluck! 😈


## 1. Penetapan Batasan Sumber Daya (Resource Constraint) 🛠️

Penetapan batasan ini adalah respons realistis terhadap keterbatasan infrastruktur (satu kluster K8s/VM bersama) sekaligus memastikan setiap mahasiswa diuji secara adil dan mendalam.

### A. Skenario Individual (Fokus pada Konfigurasi dan Keamanan)

| Fokus | Deskripsi Detail | Justifikasi Terhadap Batasan Sumber Daya |
| :--- | :--- | :--- |
| **Output Utama** | *File* konfigurasi unik (`.drone.yml`, `deployment.yaml`, `service.yaml`) yang di-*push* ke *repository* Gitea pribadi. | Penilaian bergeser dari keberhasilan eksekusi *deployment* real-time (yang memerlukan *resource* besar) ke **kebenaran, kelengkapan, dan keamanan kode konfigurasi**. |
| **Lingkungan Testing** | Mahasiswa menggunakan **kluster K8s bersama** (shared/bergantian) tetapi **hanya boleh *deploy* ke *namespace* unik** mereka (misalnya, `dev-arif`). | Mencegah konflik *resource* di antara mahasiswa. Setiap orang memiliki "ruang aman" sendiri untuk *testing* PoLP (Prinsip *Least Privilege*). |
| **Penilaian Kritis** | Penilai (Anda) dapat mengaudit *file* `.drone.yml` mahasiswa dan memverifikasi logika **`when: branch:`**, **`--exit-code 1`** (Trivy), dan referensi **`ImagePullSecret`** tanpa harus menjalankan semua *pipeline* secara serentak. | Memastikan **Aspek Keamanan dan Kontrol Alur (Workflow)** diuji, yang merupakan poin penting bagi BAN. |

### B. Skenario Kelompok (Fokus pada Proses dan Arsitektur)

| Fokus | Deskripsi Detail | Justifikasi Terhadap Batasan Sumber Daya |
| :--- | :--- | :--- |
| **Kolaborasi (Code Review)** | Anggota kelompok harus mengajukan *Pull Request* (*Merge Request*) ke *branch* `staging` atau `main` dan melakukan *review* kode satu sama lain sebelum *merge*. | Memastikan mahasiswa memahami *workflow* GitFlow yang sesungguhnya, di mana kolaborasi dan persetujuan adalah kunci, bukan hanya *scripting* individu. |
| **Arsitektur dan Dokumentasi** | Kelompok wajib menghasilkan dokumentasi akhir yang sistematis, mencakup **Flowchart End-to-End** dan **Analisis *Troubleshooting***. | Mengurangi beban eksekusi teknis berulang di *cluster* bersama, dan memindahkan fokus penilaian ke pemahaman mendalam tentang **arsitektur dan pemecahan masalah (Troubleshooting)**, poin vital untuk asesor BAN. |
| **Pembuktian RBAC** | Kelompok harus menyajikan *screenshot* atau rekaman yang membuktikan bahwa *Service Account* *deployer* mereka **gagal** jika mencoba *delete* *resource* di luar *namespace* mereka, memverifikasi PoLP. | Menguji pemahaman mereka tentang batas izin secara mendalam. |
-----

## 2. Skenario Tantangan Berjenjang (3 Level) 🧗

### Level 1: Basic CI/CD (Prasyarat) 👶

Tantangan ini menguji pemahaman dasar mahasiswa terhadap alur kerja CI/CD (Build, Push, Deploy).

| Fokus Pembelajaran Kritis | Tugas Teknis di `.drone.yml` | Output yang Diharapkan |
| :--- | :--- | :--- |
| **CI/CD Dasar** | Gunakan **`when: branch: [main]`** untuk memicu *pipeline*. | *Pipeline* harus berjalan secara otomatis dari awal hingga akhir. |
| **Package & Publish** | Gunakan `plugins/docker` untuk *build* *image* dan *push* ke **Harbor** atau **Docker Hub**. | *Image* muncul di *registry* dengan *tag* terbaru. |
| **Deployment Sederhana** | Gunakan `drone-kubectl` untuk *deploy* ke *namespace* **`dev`**. | *Pod* **`deployment/nama-app`** mencapai status **`Running`** di *namespace* `dev`. |
| **Kredensial** | Penggunaan `KUBE_TOKEN` dan kredensial *registry* yang benar. | Tidak ada error *authentication* di sepanjang *pipeline*. |

---

### Level 2: Standard (Security Gates & Multi-Lingkungan) 🧑‍💻

Level ini mengintegrasikan konsep **Quality Gate** dan pemisahan lingkungan, yang merupakan inti dari *GitLab Flow* yang efisien.

| Fokus Pembelajaran Kritis | Tugas Teknis di `.drone.yml` | Output yang Diharapkan |
| :--- | :--- | :--- |
| **Security Gates** | Tambahkan *step* **Trivy Scan** (Stage 4) di **tengah** *pipeline* (setelah Publish dan sebelum Deploy). | Jika *Scan* mendeteksi *vulnerability* **HIGH/CRITICAL**, *pipeline* harus **GAGAL** pada *step* ini (menggunakan `--exit-code 1`). |
| **Workflow Kontrol** | Pisahkan *step* **Deployment** menjadi dua: satu untuk `dev` (dari `main`) dan satu untuk `staging` (dari **`staging`**). | Perubahan pada *branch* `staging` hanya memicu *deployment* di **`namespace: staging`**. |
| **Isolation** | Pastikan `kubectl set image` menggunakan *flag* **`-n staging`** pada *step* yang benar. | Aplikasi harus berjalan di kedua *namespace* secara independen. |

---

### Level 3: Advanced (Secure GitLab Flow Penuh) 🧙

Ini adalah level tertinggi yang menguji semua konsep keamanan dan kontrol, cocok untuk mahasiswa tingkat akhir dan penilaian kelompok.

| Fokus Pembelajaran Kritis | Tugas Teknis di `.drone.yml` & K8s | Output yang Diharapkan |
| :--- | :--- | :--- |
| **Manual Approval** | Konfigurasi *step* **Deployment ke Staging** dengan **`when: trigger: manual`**. | *Pipeline* harus berhenti di *step* Deployment Staging dan menunggu persetujuan (*klik tombol*). |
| **Otentikasi K8s (Kritis)** | Konfigurasi **`ImagePullSecret`** di *Deployment Manifest* K8s di *namespace* `staging`. | *Pod* berhasil ditarik dari *registry* privat/publik tanpa error **`ImagePullBackOff`**. |
| **Pembuktian RBAC/PoLP** | Mahasiswa harus menunjukkan *Service Account* yang digunakan Drone memiliki izin **Update** di `staging`, tetapi **Gagal** jika mencoba *Delete Deployment* di *namespace* tersebut. | Menunjukkan *command* `kubectl delete deployment... -n staging` dari Drone Runner menghasilkan error **`Forbidden`**. |

---

## 3\. Instruksi Awal untuk Mahasiswa Semester 3(Level 1 Prasyarat) 🚩

**Tujuan:** Mempersiapkan lingkungan yang terisolasi dan mengamankan titik *deployment* awal.

Semua mahasiswa harus menyelesaikan prasyarat teknis ini secara individual di *cluster* bersama. Pastikan Anda mengganti `ariff` dengan inisial atau nama unik Anda untuk menghindari konflik.

### 1\. 📂 Pembuatan Multi-Namespace (Isolasi Lingkungan)

Setiap mahasiswa harus memiliki *namespace* unik sebagai ruang kerja mereka, sesuai dengan kebutuhan *GitLab Flow*.

| Aksi | Perintah Kritis | Tujuan Kritis |
| :--- | :--- | :--- |
| **Buat Dev** | `kubectl create namespace dev-<nama-anda>` | Lingkungan *deployment* otomatis (Level 1 & 2). |
| **Buat Staging** | `kubectl create namespace staging-<nama-anda>` | Lingkungan *deployment* manual (Level 2 & 3). |

> **Contoh:**
>
> ```bash
> kubectl create namespace dev-ariff
> kubectl create namespace staging-ariff
> ```

### 2\. 🔑 Konfigurasi RBAC Dasar (Prinsip *Least Privilege*)

Verifikasi dan buat `RoleBinding` baru agar `ServiceAccount/drone-deployer` hanya memiliki izin `update/patch` pada *resource* **Deployment** di *namespace* unik Anda.

  * **Aksi Kritis:** Pastikan Anda membuat `RoleBinding` di *namespace* `dev-ariff` yang mengikat `ServiceAccount/drone-deployer` ke `ClusterRole/drone-updater` (atau *Role* sejenis).
  * **Tujuan:** Membuktikan bahwa *token* K8s yang akan Anda masukkan ke Drone CI **tidak memiliki izin di luar batas yang diperlukan** (Level 3).

### 3\. 📝 Basic Deployment Setup (Kesiapan *Patch*)

Siapkan *Deployment* K8s sederhana yang akan menjadi target *patching* oleh *pipeline* Drone CI Anda. Manifest ini harus dimasukkan ke *namespace* unik Anda.

  * **Aksi Kritis:** Buat file `deployment.yaml` yang ditempatkan di *namespace* `dev-ariff`.
  * **ImagePullSecret (Kritis):** *Manifest* ini harus secara eksplisit **merujuk** pada `ImagePullSecret`, meskipun *secret* itu sendiri baru dikonfigurasi penuh di Level 3.

**Contoh Fragmen Deployment K8s:**

```yaml
# ... (bagian lain)
spec:
  template:
    spec:
      containers:
      - name: web-container
        image: placeholder/myapp:v1.0.0 
      # Wajib merujuk pada ImagePullSecret (Harbor atau Docker Hub)
      imagePullSecrets:
      - name: harbor-pull-secret 
```
