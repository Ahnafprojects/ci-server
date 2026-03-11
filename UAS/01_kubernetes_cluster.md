## Kubernetes Cluster

Modul ini berfokus pada penggunaan *Infrastructure as Code* (IaC) untuk menyiapkan *cluster* Kubernetes *multi-node* menggunakan **Vagrant** sebagai fondasi dan **Kubeadm** sebagai alat orkestrasi.

## 🎯 1. Definisi dan Kebutuhan Cluster Otomatis

Modul ini memanfaatkan *tool* otomasik untuk menyiapkan **Lingkungan Cluster Kubernetes Lokal** yang menyerupai arsitektur produksi, namun sepenuhnya berjalan di Mesin Virtual (VM).

### A. Kubeadm (Kubernetes Administrator Tool)

| Konsep | Penjelasan | Fungsi Utama dalam Modul |
| :--- | :--- | :--- |
| **Kubeadm** | **Alat resmi Kubernetes** yang dirancang untuk menginisiasi (*bootstrap*) *cluster* dengan cara yang sederhana, namun sesuai standar *best-practice* Kubernetes. | **Mengotomasi instalasi Control Plane (Master)**, menghasilkan sertifikat keamanan, dan memberikan *join token* unik. Ini sangat mengurangi *error* manual. |
| **Peran Sentral** | Kubeadm bertanggung jawab untuk memasang komponen penting seperti **API Server, etcd, Scheduler**, dan **Controller Manager** di *Master Node*. | Mengubah VM kosong menjadi **Master Node** Kubernetes hanya dengan satu perintah: `kubeadm init`. |


### B. Vagrantfile Kubeadm (Infrastructure as Code)

`Vagrantfile` dalam konteks *setup* Kubernetes ini jauh lebih kompleks dibandingkan *setup* CI/CD satu node sebelumnya.

| Konsep | Penjelasan | Fungsi Kritis dalam Modul |
| :--- | :--- | :--- |
| **Vagrantfile Kubeadm** | *File* ini dikustomisasi untuk mendefinisikan *cluster* **multi-node** (satu Master dan beberapa Worker) dalam satu skrip. | **Menyiapkan Kerangka Multi-VM:** Mendefinisikan **Master Node** dan **Worker Node** secara terpisah, memberikan alokasi *resource* dan IP statis yang berbeda untuk setiap peran. |
| **Struktur Multi-VM** | Menggunakan *loop* atau definisi eksplisit (`config.vm.define`) untuk membuat beberapa VM yang saling terhubung dalam satu jaringan privat. | Memungkinkan mahasiswa untuk menguji *scheduling* dan komunikasi *pod* antar-node, yang merupakan prinsip inti Kubernetes. |

---

### C. Provisioning Script (Konsistensi Instalasi)

*Provisioning* adalah kunci untuk menjamin bahwa semua node siap menerima perintah Kubeadm.

| Konsep | Penjelasan | Fungsi Kritis dalam Modul |
| :--- | :--- | :--- |
| **Provisioning Script** | *Script* **Shell** atau **Ansible** yang dijalankan Vagrant di setiap VM segera setelah OS *booting*. | **Menjamin Konsistensi *Tools***: Memastikan semua node (Master dan Worker) memiliki versi **Docker**, **Kubeadm**, **Kubelet**, dan **kubectl** yang *identik* dan terinstal dengan konfigurasi jaringan yang benar (misalnya, menonaktifkan *swap*). |
| **Peran Otomasi** | *Script* ini juga yang akan menjalankan perintah `kubeadm init` di Master dan `kubeadm join` di Worker. | **Memangkas Waktu *Setup***: Mahasiswa tidak perlu menjalankan instalasi dasar di setiap VM satu per satu, mempercepat fokus pada *deploy* aplikasi. |



## 💻 2. Layout Konfigurasi Cluster (Struktur `Vagrantfile`)

`Vagrantfile` untuk *cluster* Kubernetes harus dirancang secara khusus untuk mendefinisikan dan membedakan peran setiap Mesin Virtual (VM). Ini dicapai dengan menggunakan sintaks *multi-VM* di dalam *file* konfigurasi tunggal.

### A. Konfigurasi Master Node (Control Plane) 👑

Master Node adalah otak dari *cluster*, bertanggung jawab atas semua keputusan dan status *cluster*. Vagrant mendefinisikannya dengan alokasi sumber daya yang lebih tinggi dan IP yang menjadi titik awal jaringan *cluster*.

| Komponen | Tujuan Konfigurasi | Detail Teknis (Contoh) |
| :--- | :--- | :--- |
| **Peran Utama** | Menjalankan Control Plane, yang terdiri dari **API Server** (gerbang utama *cluster*), **Scheduler**, **Controller Manager**, dan **etcd** (basis data status *cluster*). | Master harus memiliki *resource* yang stabil. |
| **Alokasi RAM** | **Lebih besar** (Minimal **2 GB** atau 2048 MB). | *Control Plane* adalah komponen paling haus memori; alokasi RAM yang memadai diperlukan agar etcd berfungsi dengan baik. |
| **Jaringan Statis** | IP awal di jaringan privat. | Contoh: `192.168.5.10`. IP ini menjadi alamat target bagi semua *Worker Node* untuk bergabung. |
| **Kode di `Vagrantfile`** | Menggunakan `config.vm.define "master"` untuk mengisolasi *setting* Master. |

### B. Konfigurasi Worker Node (Compute Layer) 👷

*Worker Node* adalah mesin yang menjalankan *workload* (aplikasi) Anda dalam bentuk *Pod*. Vagrant mendefinisikannya dalam jumlah jamak (bisa 1, 2, atau lebih *worker*).

| Komponen | Tujuan Konfigurasi | Detail Teknis (Contoh) |
| :--- | :--- | :--- |
| **Peran Utama** | Menjalankan **Kubelet** (agen komunikasi dengan Master) dan **Container Runtime** (misalnya, Docker) untuk menjalankan *Pod* aplikasi. | *Worker* adalah *layer* komputasi di mana *deployment* Anda akan dijadwalkan. |
| **Alokasi RAM** | **Sedang** (Minimal **1 GB** atau 1024 MB per *node*). | *Resource* harus mencukupi untuk OS, Docker, dan *Pod* yang dijadwalkan. Jumlah RAM sering dikurangi untuk menghemat *resource* Host. |
| **Jaringan Statis** | IP statis **berurutan**. | Contoh: `192.168.5.11`, `192.168.5.12`. Memudahkan pengelolaan dan *troubleshooting* jaringan. |
| **Kode di `Vagrantfile`** | Menggunakan *loop* atau definisi terpisah untuk membuat `worker-1`, `worker-2`, dst. |

### C. Provisioning Script (Instalasi Tools Inti) 🛠️

*Provisioning* adalah bagian krusial yang memastikan setiap VM siap menjadi anggota *cluster*.

| Komponen | Tujuan Konfigurasi | Detail Teknis (Contoh) |
| :--- | :--- | :--- |
| **Tools Inti** | Instalasi *package* yang dibutuhkan oleh Kubeadm. | Di *setup* berbasis Debian/Ubuntu, *script* menjalankan `apt-get install` untuk: **Docker**, **Kubeadm**, **Kubelet**, dan **Kubectl**. |
| **Nonaktifkan Swap** | Kubelet mengharuskan **Swap dinonaktifkan** agar berfungsi dengan benar. | *Provisioning script* akan menjalankan perintah `swapoff -a` dan memodifikasi `/etc/fstab` di **semua node**. |
| **Eksekusi Kubeadm** | Skrip juga menjalankan perintah *bootstrapping* utama. | Skrip Kubeadm akan menjalankan `kubeadm init` di Master dan `kubeadm join` di Worker, mengotomasi seluruh proses pembentukan *cluster*. |

---

## 🚀 3. Alur Instalasi Cepat (Zero-Touch Setup)

### A. Persiapan Lingkungan Host (Mengambil Blueprint)

Langkah awal adalah mengunduh *blueprint* cluster yang telah didefinisikan dalam *repository* yang mengandung `Vagrantfile` dan *script* *provisioning* yang telah disiapkan.

1.  **Kloning *Repository***: Mengunduh *boilerplate* `Vagrantfile` dan *script* *provisioning* ke komputer Host Anda.
    ```bash
    git clone https://github.com/techiescamp/vagrant-kubeadm-kubernetes.git
    ```
2.  **Masuk Direktori Kerja**: Pindah ke direktori yang berisi `Vagrantfile` yang dikustomisasi.
    ```bash
    cd vagrant-kubeadm-kubernetes
    ```

### B. Inisiasi Cluster (Satu Perintah Otomasi)

Ini adalah langkah *Zero-Touch Setup* yang membedakan pendekatan ini dari instalasi manual, yang biasanya memakan waktu berjam-jam.

3.  **Mulai Cluster: `vagrant up`**
    Perintah ini memicu seluruh *pipeline* otomasi, yang secara bertahap melakukan:

      * **Pembuatan VM:** Vagrant membaca `Vagrantfile` dan membuat semua VM (Master Node dan Worker Node).
      * **Provisioning Tools:** Menjalankan *script provisioning* (di dalam setiap VM) untuk menginstal Docker, Kubelet, Kubeadm, dan Kubectl.
      * **`kubeadm init` (Otomatis):** Di Master Node, *script* akan menjalankan `kubeadm init` untuk *bootstrapping* Control Plane.
      * **`kubeadm join` (Otomatis):** Di setiap Worker Node, *script* akan menggunakan *join token* yang dihasilkan Master untuk menjalankan `kubeadm join`, secara otomatis menghubungkan *Worker* ke *Cluster*.

    <!-- end list -->

    ```bash
    vagrant up
    ```

### C. Verifikasi Cluster (Validasi Fungsional)

Setelah proses `vagrant up` selesai (yang mungkin memakan waktu 10-20 menit tergantung kecepatan Host dan internet), mahasiswa harus memverifikasi bahwa *cluster* benar-benar *Ready*.

4.  **Akses Master Node**: Masuk ke VM Master melalui SSH. (Master adalah *node* tempat `kubectl` dikonfigurasi).

    ```bash 
    # ganti dengan nama vm master "controlplane"
    vagrant ssh master
    ```

5.  **Cek Status Node**: Memverifikasi bahwa semua node sudah terhubung, dan statusnya **`Ready`**, yang mengindikasikan Control Plane dan CNI (*Cluster Network Interface*) berfungsi.

    ```bash
    kubectl get nodes
    ```

      * **Hasil yang Diharapkan:** Output harus menunjukkan **Master** dan semua **Worker Node** dengan status **`Ready`**. Status ini memastikan *cluster* siap menerima *workload* (Deployment dan Pod).

-----

### 4. Peran Kubeadm dalam Otomasi Cluster 🔧


Kubeadm adalah alat *bootstrap* yang mengubah VM Linux biasa menjadi *node* Kubernetes yang berfungsi penuh. Dalam *setup* otomatis Vagrant, *script provisioning* memastikan setiap langkah Kubeadm dieksekusi pada *node* yang tepat.

| Langkah Kubeadm | Di mana Dijalankan | Fungsi Detail |
| :--- | :--- | :--- |
| **`kubeadm init`** | **Master Node** | Perintah ini adalah inti dari pembentukan *cluster*. Ia melakukan semua pengaturan Control Plane yang kompleks:<br>\* **Memasang Komponen Control Plane:** Mengunduh dan menjalankan komponen penting seperti **API Server**, **Scheduler**, **Controller Manager**, dan **etcd** sebagai *container* statis.<br>\* **Manajemen Sertifikat:** Membuat dan mendistribusikan sertifikat keamanan (X.509) untuk komunikasi antar komponen (*TLS/SSL*).<br>\* **Token Otentikasi:** Menghasilkan **`join token`** unik yang diperlukan oleh Worker Node untuk bergabung secara aman ke *cluster*. |
| **`kubeadm join`** | **Worker Node** | Setelah Master siap, perintah ini dieksekusi pada setiap Worker Node untuk menghubungkannya ke Master.<br>\* **Self-Register:** Menggunakan *join token* dan alamat Master Node untuk mendaftarkan dirinya ke API Server.<br>\* **Kubelet:** Mengkonfigurasi *Kubelet* (agen pada Worker) agar dapat mendengarkan perintah penjadwalan dari Master dan menjalankan *Pod*.<br>\* **Status Node:** Setelah sukses, Node akan muncul di Master dengan status awal `Ready`. |
| **CNI (Networking)** | **Master Node** | *Container Network Interface* (CNI) adalah solusi jaringan yang harus dipasang *setelah* `kubeadm init` selesai.<br>\* **Jaringan *Pod*:** Menginstal *addon* jaringan (seperti Flannel, Calico, atau Weave) yang menciptakan lapisan jaringan virtual di atas jaringan Host. CNI memungkinkan *Pod* yang berada di *Node* yang berbeda dapat saling berkomunikasi.<br>\* **Kondisi `NotReady`:** Tanpa CNI, *Node* dan *Pod* mungkin berada dalam status `NotReady` atau `Pending` karena jaringan *inter-pod* belum terbentuk. |

Dengan mengotomasi ketiga langkah ini, *script* Vagrant memastikan *cluster* Kubernetes siap untuk *deployment* aplikasi tanpa intervensi manual yang rentan terhadap kesalahan konfigurasi.

-----

**Tindakan Selanjutnya:** Apakah Anda ingin saya membuatkan materi detail untuk masing-masing perintah Kubeadm (`init` dan `join`) atau fokus pada *troubleshooting* jika instalasi cepat ini gagal?