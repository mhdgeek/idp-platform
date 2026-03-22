import click
import subprocess
import yaml
import os
import sys
from pathlib import Path


VALID_ENVS = ["dev", "staging", "prod"]

REPLICAS_DEFAULT = {
    "dev":     1,
    "staging": 2,
    "prod":    3,
}

RESOURCE_PRESETS = {
    "dev":     {"cpu_request": "50m",  "memory_request": "64Mi",  "cpu_limit": "200m",  "memory_limit": "256Mi"},
    "staging": {"cpu_request": "100m", "memory_request": "128Mi", "cpu_limit": "400m",  "memory_limit": "512Mi"},
    "prod":    {"cpu_request": "200m", "memory_request": "256Mi", "cpu_limit": "800m",  "memory_limit": "1Gi"},
}


def generate_manifest(app: str, env: str, image: str, replicas: int, port: int) -> dict:
    """Generate a complete Kubernetes manifest for the app."""
    resources = RESOURCE_PRESETS[env]

    manifest = {
        "apiVersion": "apps/v1",
        "kind": "Deployment",
        "metadata": {
            "name": app,
            "namespace": env,
            "labels": {
                "app": app,
                "env": env,
                "managed-by": "idp-cli"
            }
        },
        "spec": {
            "replicas": replicas,
            "selector": {"matchLabels": {"app": app}},
            "strategy": {
                "type": "RollingUpdate",
                "rollingUpdate": {"maxSurge": 1, "maxUnavailable": 0}
            },
            "template": {
                "metadata": {
                    "labels": {"app": app, "env": env}
                },
                "spec": {
                    "serviceAccountName": "deployer",
                    "containers": [{
                        "name": app,
                        "image": image,
                        "ports": [{"containerPort": port}],
                        "resources": {
                            "requests": {
                                "cpu": resources["cpu_request"],
                                "memory": resources["memory_request"]
                            },
                            "limits": {
                                "cpu": resources["cpu_limit"],
                                "memory": resources["memory_limit"]
                            }
                        },
                        "livenessProbe": {
                            "httpGet": {"path": "/health", "port": port},
                            "initialDelaySeconds": 10,
                            "periodSeconds": 10,
                            "failureThreshold": 3
                        },
                        "readinessProbe": {
                            "httpGet": {"path": "/health", "port": port},
                            "initialDelaySeconds": 5,
                            "periodSeconds": 5,
                            "failureThreshold": 2
                        }
                    }]
                }
            }
        }
    }

    service = {
        "apiVersion": "v1",
        "kind": "Service",
        "metadata": {
            "name": app,
            "namespace": env,
            "labels": {"app": app, "env": env, "managed-by": "idp-cli"}
        },
        "spec": {
            "selector": {"app": app},
            "ports": [{"port": 80, "targetPort": port}],
            "type": "ClusterIP"
        }
    }

    return [manifest, service]


@click.command()
@click.option("--app",      required=True,  help="Application name")
@click.option("--env",      required=True,  type=click.Choice(VALID_ENVS), help="Target environment")
@click.option("--image",    default="nginx:alpine", help="Docker image (default: nginx:alpine)")
@click.option("--replicas", default=None,   type=int, help="Number of replicas (default: env preset)")
@click.option("--port",     default=80,     type=int, help="Container port (default: 80)")
@click.option("--dry-run",  is_flag=True,   help="Print manifest without applying")
def deploy(app, env, image, replicas, port, dry_run):
    """🚀 Deploy an application to the platform."""

    if replicas is None:
        replicas = REPLICAS_DEFAULT[env]

    click.echo(f"\n  🚀 Deploying {click.style(app, fg='cyan', bold=True)} to {click.style(env, fg='yellow', bold=True)}")
    click.echo(f"     Image    : {image}")
    click.echo(f"     Replicas : {replicas}")
    click.echo(f"     Port     : {port}")

    manifests = generate_manifest(app, env, image, replicas, port)

    # Save manifests to repo
    output_dir = Path(f"apps/{app}/{env}")
    output_dir.mkdir(parents=True, exist_ok=True)
    manifest_path = output_dir / "deployment.yml"

    with open(manifest_path, "w") as f:
        yaml.dump_all(manifests, f, default_flow_style=False)

    click.echo(f"\n  📄 Manifest saved → {manifest_path}")

    if dry_run:
        click.echo("\n  📋 Dry run — manifest preview:\n")
        with open(manifest_path) as f:
            click.echo(f.read())
        return

    # Apply via kubectl
    click.echo(f"\n  ⚙️  Applying to Kubernetes...")
    result = subprocess.run(
        ["kubectl", "apply", "-f", str(manifest_path), "--validate=false"],
        capture_output=True, text=True
    )

    if result.returncode == 0:
        click.echo(f"  {result.stdout.strip()}")
        click.echo(f"\n  ✅ {click.style('Deployed successfully!', fg='green', bold=True)}")
        click.echo(f"\n  📊 Check status : idp status --app {app} --env {env}")
        click.echo(f"  📜 View logs    : idp logs --app {app} --env {env}\n")
    else:
        click.echo(f"\n  ❌ Deploy failed:\n{result.stderr}", err=True)
        sys.exit(1)
