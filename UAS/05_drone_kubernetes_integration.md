# Integrasi Drone CI dan Kubernetes

## 🚢 1. Konsep Dasar: Agen Deployment

### A. Peran Drone Runner sebagai Mesin Eksekusi (`kubectl`)

Dalam arsitektur CI/CD berbasis *container*, **Drone Runner** adalah komponen yang secara fisik menjalankan instruksi yang tertulis di *file* `.drone.yml` Anda.

* **Bukan Server:** Drone Server hanya bertugas mengorkestrasi dan mengelola antarmuka web. Runner-lah yang berfungsi sebagai **Agen Deployment**.
* **Mengeksekusi `kubectl`:** Ketika *pipeline* Drone CI mencapai *step* *deployment* Kubernetes, Drone Runner akan menjalankan *plugin* atau *container* khusus yang berisi utilitas **`kubectl`**.
* **Akses *Host*:** Melalui *volume mapping* `/var/run/docker.sock`, Drone Runner memiliki kemampuan untuk membuat *container* baru di dalam *Host* VM (tempat ia berjalan). Ini memungkinkannya menjalankan *container* sementara (misalnya `drone-kubectl`) yang kemudian berkomunikasi dengan *Kubernetes Cluster* Anda.

### B. Otentikasi Kritis: Prinsip *Least Privilege* (Izin Minimal) 🔒

Ini adalah bagian terpenting dari integrasi yang aman. Setiap *tool* otomatis yang berinteraksi dengan *Cluster* Kubernetes harus memiliki izin akses sekecil mungkin yang hanya dibutuhkan untuk menjalankan tugasnya.

#### Mengapa Kita Tidak Boleh Menggunakan Kredensial Admin?

1.  **Risiko Keamanan:** Jika kredensial admin (*Cluster Admin*) terekspos (misalnya, di dalam *logs* Drone atau dicuri dari *server*), penyerang akan mendapatkan akses tak terbatas ke seluruh *Cluster* Anda, termasuk kemampuan untuk menghapus *namespace* produksi, memodifikasi *Service Account* lain, atau menyuntikkan *malware*.
2.  **Audit dan Kepatuhan:** Menggunakan satu akun umum (admin) membuat sulit untuk melacak siapa atau apa yang menyebabkan perubahan tertentu. Anda tidak dapat membedakan apakah perubahan dilakukan oleh manusia atau oleh *pipeline* CI/CD.

#### Solusi: Kubernetes Service Account Khusus

Kita wajib menggunakan **Service Account** yang diciptakan khusus untuk Drone CI.

* **Definisi:** **Service Account** adalah identitas non-manusia di Kubernetes.
* **Tujuan:** Kita akan memberikan **Role** (`RoleBinding`) kepada **Service Account** Drone yang hanya mencakup izin: **CREATE, UPDATE, DELETE** pada *resource* **Deployment, Service, dan Ingress** di *namespace* yang spesifik (misalnya, `dev`).
* **Justifikasi:** Jika **Token Rahasia** dari *Service Account* ini terekspos, kerusakannya terbatas hanya pada operasi *deployment* di *namespace* tersebut. Ia tidak dapat menghapus *cluster* atau memengaruhi *namespace* lainnya. Ini adalah implementasi langsung dari prinsip **Least Privilege**.

---


## 🔑 2. Penyiapan Kubernetes untuk Drone CI

Langkah ini bertujuan membuat identitas khusus di Kubernetes, yaitu **Service Account**, dan memberikannya izin minimal yang dibutuhkan untuk *deployment*.

### A. Pembuatan Service Account (Identitas Drone)

Service Account ini akan berfungsi sebagai identitas non-manusia yang digunakan oleh Drone CI untuk *login* ke *cluster*.

1.  **Buat File YAML:** Buat *file* bernama `drone-sa.yaml` dan definisikan **Service Account** di *namespace* yang akan digunakan untuk *deployment* (misalnya `dev`).

    ```yaml
    # drone-sa.yaml
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: drone-deployer
      namespace: dev # Ganti dengan namespace target Anda
    ```

2.  **Terapkan ke Cluster:**

    ```bash
    kubectl apply -f drone-sa.yaml
    ```

### B. Role dan RoleBinding (Definisi Izin)

Kita akan membuat **Role** yang mendefinisikan izin spesifik, kemudian menggunakan **RoleBinding** untuk mengaitkan izin tersebut dengan **Service Account** `drone-deployer`.

1.  **Buat File YAML (Role dan RoleBinding):** Buat *file* bernama `drone-role.yaml` yang berisi definisi **Role** dan **RoleBinding** dalam satu *namespace*.

    ```yaml
    # drone-role.yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: Role
    metadata:
      name: drone-deploy-role
      namespace: dev
    rules:
    - apiGroups: ["", "apps"] # Core API (pods, services) dan Apps API (deployments)
      resources: ["deployments", "services", "ingresses", "pods", "secrets", "configmaps"]
      verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: drone-deployer-binding
      namespace: dev
    subjects:
    - kind: ServiceAccount
      name: drone-deployer # Service Account yang dibuat di langkah A
      namespace: dev
    roleRef:
      kind: Role
      name: drone-deploy-role # Role yang baru dibuat
      apiGroup: rbac.authorization.k8s.io
    ```

      * **Justifikasi:** `verbs` yang diberikan (*get, list, watch, create, update, delete*) adalah izin minimal yang diperlukan untuk mengelola *resource* *deployment* (`deployments`, `services`, dll.) dan tidak memberikan akses ke *cluster* secara keseluruhan.

2.  **Terapkan ke Cluster:**

    ```bash
    kubectl apply -f drone-role.yaml
    ```

### C. Mendapatkan Token Rahasia (Kredensial)

Token ini adalah kredensial yang akan disalin dan disimpan sebagai **Secret** di Drone CI. Sejak Kubernetes v1.24, Token Secret harus dibuat secara eksplisit.

1.  **Buat Secret Token untuk SA:** Buat *token* unik yang terkait dengan `drone-deployer` Service Account.

    ```yaml
    # drone-token-secret.yaml
    apiVersion: v1
    kind: Secret
    metadata:
      name: drone-deployer-token
      annotations:
        kubernetes.io/service-account.name: drone-deployer
    type: kubernetes.io/service-account-token
    ```

    ```bash
    kubectl apply -f drone-token-secret.yaml -n dev
    ```

2.  **Ekstrak Token (Base64 Decode):** Ambil nilai token dari *Secret* yang baru dibuat dan dekode dari Base64. Ini adalah string kredensial yang panjang.

    ```bash
    # Perintah untuk mendapatkan dan mendekode token secara langsung
    DRONE_TOKEN=$(kubectl get secret drone-deployer-token -n dev -o jsonpath='{.data.token}' | base64 -d)

    echo $DRONE_TOKEN
    ```

Token yang muncul di *output* (variabel `$DRONE_TOKEN`) adalah **Service Account Token Rahasia** yang akan digunakan Drone CI untuk setiap perintah `kubectl`. Simpan *string* ini dengan sangat hati-hati.

Langkah selanjutnya adalah menguji token ini secara manual (sesuai saran Anda) sebelum mengintegrasikannya ke Drone CI.

---

## ✨ 3. Pengujian Service Account

Tujuan utama dari pengujian ini adalah memvalidasi dua hal: **Konektivitas** (apakah token berfungsi) dan **Keamanan** (apakah izinnya terbatas sesuai prinsip *Least Privilege*).

Asumsikan Anda sudah berada di terminal **Vagrant VM** dan variabel `$DRONE_TOKEN` sudah terisi dengan *Service Account Token* yang diekstrak sebelumnya.

### A. Uji Akses Manual (Verifikasi Konektivitas)

Untuk menjalankan `kubectl` menggunakan *Service Account Token*, kita harus menyediakan tiga informasi: **Token**, **Alamat API Server**, dan **Sertifikat CA** (untuk HTTPS).

#### 1\. Menentukan Alamat API Server

Dapatkan alamat API Server Kubernetes Anda.

```bash
# Ambil alamat API Server dari konfigurasi cluster-info
KUBE_SERVER=$(kubectl cluster-info | grep 'Kubernetes control plane' | awk '{print $NF}')

echo "Alamat API Server: $KUBE_SERVER"
```

*(Asumsikan Kubeconfig ada di VM, jika tidak, mahasiswa perlu mendapatkan alamat IP Master Node dan port 6443 dari setup cluster mereka)*

#### 2\. Uji Coba Perintah Dasar

Gunakan perintah `kubectl` dengan *flag* `--token` dan `--server` untuk mengotentikasi sebagai `drone-deployer`.

```bash
# Uji coba untuk melihat Daftar Pod di namespace 'dev'
# Perintah ini TIDAK menggunakan Kubeconfig normal, tapi menggunakan TOKEN SA
kubectl --token="$DRONE_TOKEN" --server="$KUBE_SERVER" get pods -n dev
```

  * **Hasil yang Diharapkan (Berhasil):** *Output* menampilkan daftar *Pods* di *namespace* `dev` (mungkin kosong atau menampilkan Pod *Controller*).
  * **Hasil Kegagalan (Token Salah/Izin Ditolak):** Menerima pesan `Error from server (Forbidden)` atau `error: You must be logged in to the server (Unauthorized)`. Jika gagal, periksa kembali token dan *RoleBinding*.

### B. Validasi Izin (Prinsip *Least Privilege*)

Setelah konektivitas terverifikasi, kita menguji batasan izin (*Role* yang diberikan pada langkah 2B).

#### 1\. Uji **Izin yang Diperbolehkan (Authorized Action)**

Kita akan menguji apakah Service Account dapat melakukan *deployment* (seperti yang diizinkan dalam `drone-deploy-role`).

```bash
# 1. Buat file deployment sederhana untuk diuji
cat <<EOF > test-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-sa-nginx
  namespace: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-test
  template:
    metadata:
      labels:
        app: nginx-test
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
EOF

# 2. Terapkan Deployment menggunakan Token SA
kubectl --token="$DRONE_TOKEN" --server="$KUBE_SERVER" apply -f test-deployment.yaml -n dev
```

  * **Hasil yang Diharapkan (Berhasil):** Menerima pesan `deployment.apps/test-sa-nginx created`.
  * **Finalisasi:** Jika berhasil, hapus *deployment* uji ini.
    ```bash
    kubectl --token="$DRONE_TOKEN" --server="$KUBE_SERVER" delete deployment test-sa-nginx -n dev
    ```

#### 2\. Uji **Izin yang Dilarang (Unauthorized Action)**

Kita akan menguji apakah *Service Account* **tidak dapat** melakukan operasi tingkat *cluster* (yang hanya boleh dilakukan oleh Admin).

```bash
# Uji coba: Mencoba melihat daftar Node di seluruh Cluster (Cluster-Scoped Resource)
kubectl --token="$DRONE_TOKEN" --server="$KUBE_SERVER" get nodes
```

  * **Hasil yang Diharapkan (Berhasil Memblokir):** Menerima pesan `Error from server (Forbidden)`.
  * **Justifikasi:** Role kita hanya berlaku di *namespace* `dev` (Role-Scoped). Karena `nodes` adalah sumber daya *Cluster-Scoped*, *Service Account* ini dilarang untuk melihatnya, memvalidasi bahwa prinsip *Least Privilege* telah diterapkan dengan benar.

Setelah kedua pengujian ini sukses, Anda yakin bahwa **Token** yang Anda miliki **sah** dan **aman** untuk diinjeksikan ke Drone CI. Langkah selanjutnya adalah menyimpan token ini sebagai **Secret** di Drone CI.

---

## 🔒 4. Konfigurasi Drone CI (`.drone.yml`) dan Kredensial Rahasia

### A. Variabel Rahasia Drone (Secrets) 🤫

Token Service Account yang sudah diekstrak tidak boleh disimpan langsung di *file* `.drone.yml` karena *file* tersebut disimpan di Git (Gitea) dan bersifat publik bagi *developer* yang memiliki akses. Drone CI menyediakan mekanisme **Secrets** untuk menyimpan kredensial sensitif secara aman dan terenkripsi.

#### Perbedaan *Environment Variable* Biasa dan *Secret* Terenkripsi:

| Fitur | Variabel Lingkungan Biasa | Secret Terenkripsi Drone |
| :--- | :--- | :--- |
| **Lokasi Penyimpanan** | Disimpan di dalam *file* `.drone.yml` atau *Build Config*. | Disimpan terpisah di **Database Drone Server** (terenkripsi AES-256). |
| **Keamanan** | **Tidak aman**, terekspos di Git. | **Aman**, tidak pernah terekspos di Git maupun di *build logs*. |
| **Penggunaan** | Untuk nilai non-sensitif (misalnya, nama *branch*, versi). | Untuk kredensial (API Keys, **Service Account Token**, *password* Harbor). |

#### Langkah Penyimpanan Token di Drone:

1.  **Akses Drone UI:** *Login* ke Drone CI (`http://192.168.56.10:8000`).
2.  **Pilih Repository:** Navigasi ke *repository* yang ingin Anda *deploy*.
3.  **Pengaturan Secrets:** Masuk ke menu **Settings** \> **Secrets**.
4.  **Buat Secret Baru:**
      * **Name:** Beri nama, misalnya **`KUBE_TOKEN`**.
      * **Value:** *Paste* seluruh *string* **Service Account Token** yang sudah Anda ekstrak dan dekode.
5.  **Simpan:** Drone akan menyimpan nilai ini secara terenkripsi.

### B. Pengenalan Plugin `drone-kubectl` ⚙️

Untuk menjalankan perintah *deployment* Kubernetes, Drone menggunakan **Plugin** yang berupa *Docker Image* khusus. Plugin yang paling sering digunakan untuk interaksi dengan K8s adalah `drone-kubectl`.

  * **Fungsi:** Plugin ini mengemas perintah `kubectl` dan semua *dependency*-nya, memungkinkan *pipeline* menjalankan *deployment* tanpa harus menginstal `kubectl` di *runner* secara manual.
  * **Mekanisme Otentikasi:** Plugin ini dirancang untuk menerima kredensial *cluster* (termasuk **Token**) melalui *input* yang diambil dari **Secrets**.

### C. Konfigurasi *Pipeline* di `.drone.yml`

Berikut adalah contoh *step* di *file* `.drone.yml` yang menggunakan **Secret Token** untuk otentikasi dan melakukan *deployment*.

```yaml
kind: pipeline
name: deploy-to-kubernetes

steps:
- name: build-and-push-image
  # ... step build image ke Harbor ...

- name: deploy-kubernetes
  image: lalk/drone-kubectl # Menggunakan plugin kubectl standar
  settings:
    # 1. OTENTIKASI: Menggunakan Token yang disimpan sebagai Secret
    kubernetes_server: https://<IP_API_SERVER_K8S>:6443 # Ganti dengan Alamat IP API Master Node K8S Anda
    kubernetes_token:
      from_secret: KUBE_TOKEN # Ambil nilai Secret bernama KUBE_TOKEN

    # 2. DEFINISI DEPLOYMENT: File yang akan diterapkan
    script:
      - kubectl apply -f deploy/deployment.yaml -n dev
      - kubectl apply -f deploy/service.yaml -n dev
    
    # 3. OPSIONAL: Membutuhkan verifikasi sertifikat (tergantung setup K8s)
    # insecureskipverify: true 
    
    # 4. KONDISI: Hanya jalankan step ini jika merge ke branch 'main'
    when:
      branch:
        - main
```

**Penjelasan Kritis:**

1.  **`kubernetes_token: from_secret: KUBE_TOKEN`**: Baris ini memberi instruksi kepada Drone untuk mengambil nilai dari **Secret** bernama `KUBE_TOKEN` yang tersimpan aman di *database* Drone dan menyediakannya ke plugin `drone-kubectl` sebagai *token* otentikasi.
2.  **`kubernetes_server`**: Anda harus memasukkan alamat **API Server** Kubernetes yang benar (misalnya IP Node Master dan port **6443**). Drone Runner harus dapat mencapai alamat ini dari dalam VM Vagrant.

* Dengan konfigurasi ini, *pipeline* Anda dapat melakukan *deployment* ke Kubernetes secara otomatis menggunakan izin yang **terbatas** dan **aman** dari **Service Account** `drone-deployer`.
---

## 💡 5. Strategi Deployment dan Manajemen Environment

Setelah berhasil mengotentikasi Drone CI, langkah selanjutnya adalah menentukan bagaimana *file* konfigurasi Kubernetes (manifest) akan dikelola dan diterapkan.

### A. Raw YAML: Sederhana Namun Terbatas 📝

Pendekatan paling dasar adalah menggunakan *file* YAML statis (disebut **Raw YAML**) untuk setiap *resource* (Deployment, Service, ConfigMap).

  * **Contoh:** *File* `deployment-dev.yaml` yang berisi *image tag* `myapp:v1.0.0` dan *replica count* `1`.
  * **Kelebihan:** Sangat mudah dipahami, tidak memerlukan *tool* tambahan.
  * **Keterbatasan Kritis untuk Proyek Besar:**
    1.  **Redundansi:** Jika Anda memiliki 3 *environment* (Dev, Staging, Prod), Anda harus membuat 3 salinan *file* YAML yang hampir identik.
    2.  **Manajemen Variabel:** Jika *image tag* atau *replica count* berubah, Anda harus mengubahnya di semua *file* secara manual. Drone CI harus menggunakan `sed` atau *tool* lain untuk mencari dan mengganti variabel di dalam *file* YAML sebelum menerapkannya, yang rentan terhadap kesalahan.
    3.  **Upgrade:** Mengelola *state* versi sebelumnya (*rollbacks* dan *upgrade*) menjadi rumit dan sulit dilacak.

-----

### B. Helm Charts: *Package Manager* Kubernetes (Direkomendasikan) 📦

**Helm** adalah *package manager* standar de-facto untuk Kubernetes. Helm memungkinkan Anda mendefinisikan, menginstal, dan meng-*upgrade* aplikasi Kubernetes yang kompleks sebagai satu paket (*Chart*).

  * **Konsep Chart:** Mirip dengan paket Linux (`.deb` atau `.rpm`), *Chart* Helm mengemas semua YAML Manifest yang dibutuhkan sebuah aplikasi (`Deployment`, `Service`, `ConfigMap`, dll.) ke dalam satu direktori.
  * **Manajemen Variabel (`values.yaml`):** *Chart* Helm menggunakan sistem *templating* (berbasis Go Template) yang memungkinkan Anda memisahkan konfigurasi (variabel) dari definisi *resource* (template).
      * **Contoh:** Anda hanya perlu mengubah nilai `imageTag: v1.0.1` di *file* `values-prod.yaml` tanpa menyentuh *template* Deployment YAML yang sebenarnya.
  * **Manajemen Environment:** Anda dapat menggunakan *Chart* yang sama untuk Dev, Staging, dan Prod, cukup dengan menyediakan *file* `values.yaml` yang berbeda untuk setiap *environment* saat *deployment*.
  * **Rollback & Versioning:** Helm melacak semua rilis dan versi *deployment* (*Revisions*), sehingga *rollback* ke versi sebelumnya menjadi mudah dan instan.

### C. Integrasi Helm dengan Drone CI 🔗

Integrasi Helm ke dalam *pipeline* Drone CI dilakukan dengan menggunakan **Plugin Drone-Helm**. Plugin ini mengotentikasi dan menjalankan perintah Helm secara aman.

#### Konfigurasi `.drone.yml` dengan Helm:

```yaml
# ... steps sebelumnya (build image, push ke Harbor) ...

- name: deploy-ke-staging
  image: alpine/helm:3.12.3-v0.1.0 # Plugin drone-helm yang direkomendasikan
  settings:
    # 1. AUTENTIKASI KUBERNETES: Sama seperti kubectl, menggunakan Secret Token
    kube_api_server: https://<IP_API_SERVER_K8S>:6443 
    kube_token:
      from_secret: KUBE_TOKEN # Menggunakan Secret KUBE_TOKEN
    
    # 2. PERINTAH HELM
    # upgrade --install: Upgrade jika sudah ada, install jika belum ada
    command: upgrade --install
    release: myapp-staging # Nama release Helm
    chart: ./helm/myapp-chart # Path ke Chart Helm di repository Anda
    namespace: dev # Target namespace
    
    # 3. MANAJEMEN ENVIRONMENT
    # Menggunakan values file khusus untuk environment Dev
    values_file: values-dev.yaml 
  
  when:
    branch:
      - develop
```

**Kesimpulan:** Mengintegrasikan **Helm** melalui **Drone CI** memberikan solusi *deployment* yang lebih kuat, terorganisir, dan *maintainable*, sangat cocok untuk proyek skala *enterprise* yang Anda ajarkan.
