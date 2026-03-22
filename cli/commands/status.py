import click
import subprocess
import json


@click.command()
@click.option("--app", required=True, help="Application name")
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]), help="Environment")
def status(app, env):
    """📊 Show deployment status."""

    click.echo(f"\n  📊 Status: {click.style(app, fg='cyan', bold=True)} / {click.style(env, fg='yellow', bold=True)}\n")

    # Deployment status
    result = subprocess.run(
        ["kubectl", "get", "deployment", app, "-n", env,
         "-o", "jsonpath={.status.availableReplicas}/{.spec.replicas}"],
        capture_output=True, text=True
    )

    if result.returncode != 0:
        click.echo(f"  ❌ App '{app}' not found in '{env}'")
        return

    replicas = result.stdout.strip()
    click.echo(f"  Replicas  : {replicas}")

    # Pods status
    pods = subprocess.run(
        ["kubectl", "get", "pods", "-n", env, "-l", f"app={app}",
         "--no-headers", "-o", "custom-columns=NAME:.metadata.name,STATUS:.status.phase,READY:.status.containerStatuses[0].ready,RESTARTS:.status.containerStatuses[0].restartCount"],
        capture_output=True, text=True
    )

    click.echo(f"\n  Pods:\n")
    for line in pods.stdout.strip().split("\n"):
        if line:
            parts = line.split()
            name    = parts[0] if len(parts) > 0 else "-"
            status_ = parts[1] if len(parts) > 1 else "-"
            ready   = parts[2] if len(parts) > 2 else "-"
            color   = "green" if status_ == "Running" and ready == "true" else "red"
            click.echo(f"    {click.style('●', fg=color)} {name}  [{status_}]  ready={ready}")

    click.echo("")
