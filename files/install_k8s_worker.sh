#!/bin/bash

wait_for_s3_object(){
  until aws s3 ls s3://${s3_bucket_name}/ca.txt 
  do
    echo "Waiting the ca hash ..."
    sleep 10
  done
}

render_kubejoin(){

HOSTNAME=$(hostname)
ADVERTISE_ADDR=$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
CA_HASH=$(aws s3 cp s3://${s3_bucket_name}/ca.txt -)
KUBEADM_TOKEN=$(aws s3 cp s3://${s3_bucket_name}/kubeadm_token.txt -)

cat <<-EOF > /root/kubeadm-join-worker.yaml
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: JoinConfiguration
discovery:
  bootstrapToken:
    token: $KUBEADM_TOKEN
    apiServerEndpoint: ${control_plane_url}:${kube_api_port}
    caCertHashes: 
      - sha256:$CA_HASH
localAPIEndpoint:
  advertiseAddress: $ADVERTISE_ADDR
  bindPort: ${kube_api_port}
nodeRegistration:
  criSocket: /run/containerd/containerd.sock
  imagePullPolicy: IfNotPresent
  name: $HOSTNAME
  taints: null
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd
EOF
}

k8s_join(){
  kubeadm join --config /root/kubeadm-join-worker.yaml
}

until $(curl -k --output /dev/null --silent --head -X GET https://${control_plane_url}:${kube_api_port}); do
  printf '.'
  sleep 5
done

wait_for_s3_object
render_kubejoin
k8s_join
