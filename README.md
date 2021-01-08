# rpi-cuberite-server

[Cuberite](https://github.com/cuberite/cuberite) is a Minecraft-compatible multiplayer game server that is written in C++ and designed to be efficient with memory and CPU, as well as having a flexible Lua Plugin API. Cuberite is compatible with the Java Edition Minecraft client.

## Install

This example assumes you have a k3s cluster running on ARM. See: [Kubernetes to your Raspberry Pi in 15 minutes](https://medium.com/@alexellisuk/walk-through-install-kubernetes-to-your-raspberry-pi-in-15-minutes-84a8492dc95a)

### Dockerfile

The Dockerfile currently just copies in a basic webadmin config to enable the web interface to Cuberite. It is not recommended to expose this interface to the internet.

Cuberite can be run just in docker with the following command:

```
docker run --tty -d -p 25565:25565 -p 8080:8080 rhysemmas/cuberite:armv7
```

`Note:` This does not setup a persistent volume, data will be lost when the container is removed.

### K3s

```
kubectl apply -f ./kube/
```

The manifest files in the [kube/](./kube) directory will deploy Cuberite to the current namespace, the [deployment](./kube/deploy.yaml) sets up hostPath volumes for the different worlds (world, world_nether, world_the_end) - these paths will need to exist for the hostPaths to be setup. I have a USB mounted at `/mnt` on the Pi where Cuberite runs for storing the world saves. The hostPath mounts are therefore relative to `/mnt` and will need updating to a path of your choice.

A single Cuberite pod will be deployed, the deployment specifies a nodeSelector which looks for the label: `minecraft=true` - to add this label to a node, run the following:

```
kubectl label node <node-name> minecraft=true
```

The deployment also has the following toleration:

```
      tolerations:
      - key: minecraft
        operator: Exists
        effect: NoSchedule
```

I would recommend setting up a corresponding taint, so that other pods are not scheduled on the node where you will be running Cuberite. You will, however, need to ensure that other system pods (e.g, the created svclb-cuberite daemonset, as well as other deployments in the kube-system namespace) now also have a corresponding toleration. I have multiple taints and am not worried about system pods being scheduled on any node, so the following toleration saves some time:

```
      tolerations:
      - effect: NoExecute
        operator: Exists
      - effect: NoSchedule
        operator: Exists
```

To taint the node where you will be running Cuberite, you can do the following:

```
kubectl taint node <node-name> minecraft=true:NoSchedule
```

The manifests create a service of `type: LoadBalancer`, once the service is setup, you should get an IP address for the assigned loadbalancer:

```
kubectl get svc cuberite
```

Connect to the EXTERNAL-IP shown from a (at time of writing) 1.12.2 Minecraft Java client.
