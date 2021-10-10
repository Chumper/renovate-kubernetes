# Load Helm extension
load("ext://helm_remote", "helm_remote")

# Create option for dev - prod
config.define_bool(
    "remote",
    args=False,
    usage="Set to true to deploy with remote values (requires environment to be set up)",
)
cfg = config.parse()

is_local = not cfg.get("prod", False)
env = "remote" if cfg.get("prod", False) else "local"

# define deps for local:
vault_deps = []
if local:
    vault_deps.append("Seed:Vault")

# Scheduler
k8s_yaml(kustomize("scheduler/" + env))
docker_build("renovate-scheduler", "../renovate-scheduler")
k8s_resource(env + '-renovate-scheduler', resource_deps=vault_deps + [env + "-redis-master"], labels=["Renovate"])

# REDIS
k8s_yaml(kustomize("redis/" + env))
k8s_resource(workload=env + "-redis-master", resource_deps=vault_deps, labels=["Infrastructure"])

# MINIO
k8s_yaml(kustomize("minio/" + env))
k8s_resource(workload=env + "-minio", port_forwards=["9000", "9001"], resource_deps=vault_deps, labels=["Infrastructure"])
# if is_local:
#     local_resource(
#         "Seed:Minio", 
#         cmd="bash ./minio/seed.sh", 
#         deps=["./minio/seed.sh"],
#         resource_deps=["minio"],
#         labels=["Setup"]
#     )

# VAULT
# only install if on dev, there we need to set it up ourself
if is_local:
    helm_remote(
        "vault",
        repo_name="vault",
        repo_url="https://helm.releases.hashicorp.com",
        values=["./vault/config." + env + ".yaml"]
    )
    k8s_resource(workload="vault", port_forwards="8200", labels=["Infrastructure"])
    local_resource(
        "Seed:Vault", 
        cmd="bash ./vault/seed.sh", 
        deps=["./vault/seed.sh"],
        resource_deps=["vault"],
        labels=["Setup"]
    )
