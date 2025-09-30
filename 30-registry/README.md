# Container registry and Containerlab

Containerlab is better when used with a container registry. No one loved to witness the uncontrolled proliferation of unversioned disk image (qcow2, vmdk) files shared via ftps, one drives and IM attachments.

We can do better!

Since containerlab deals with container images, it is natural to use a container registry to store them. Versioned, immutable, tagged and easily shareable with granular access control.

Whether you choose to use one of the public registries or a run a private one, the workflow is the same. Let's see what it looks like.

## Harbor registry

In this workshop we make use of an open-source registry called [Harbor](https://goharbor.io/).
It is a CNCF graduated project and is a great choice for a private registry.

The registry has been already deployed in the workshop environment, but it is quite easy to deploy yourself in your own organization. It is a single docker compose stack that can be deployed in a few minutes.

The Harbor registry offers a neat Web UI to browse the registry contents, manage users and tune access control. You can log in to the registry UI through the public IP address of the Bare Metal host (porovided during the workshop) using the `admin` user and the password available in your workshop handout.

When logged in as `admin` you can created users, repositories, browse the registry contents and many more. Managing the harbor registry is out of the scope of this workshop.

## Listing images from the registry

You can see the images in the registry UI.

![pic](https://gitlab.com/rdodin/pics/-/wikis/uploads/3f3d08696dd6bb83cf6e223a5f8f6c39/image.png)

If you want to get the list of available repositories/tags in the registry, you can use registry API.

Listing available repositories:

```bash
curl -X 'GET'  'https://{public_IP}/api/v2.0/repositories?page=1&page_size=10'  -H 'accept: application/json' -k
```

## Using images from the registry

The whole point of pushing the image to the registry is to be able to use it in the future yourself and also to share it with others. And now that we have the image in the registry, we can modify the `20-vm.clab.yml` file to make use of it:

```diff
name: vm
topology:
  nodes:
    sonic:
      kind: sonic-vm
      image: {public_IP}/library/sonic-vm:202411

    srl:
      kind: nokia_srlinux
-     image: ghcr.io/nokia/srlinux:25.3.3
+     image: {public_IP}/library/nokia_srlinux:25.3.3

  links:
    - endpoints: ["sonic:eth1", "srl:e1-1"]
```

Not only this gives us an easy way to share images with others, but also it enables stronger reproducibility of the lab, as the users of our lab would use exactly the same image that we built.