import click
import subprocess


@click.command()
@click.option("--env", default=None, type=click.Choice(["dev", "staging", "prod"]), help="Filter by environment")
def list_apps(env):
    """📋 List all deployed applications."""

    envs = [env] if env else ["dev", "staging", "prod"]

    click.echo(f"\n  📋 Deployed applications:\n")

    for e in envs:
        result = subprocess.run(
            ["kubectl", "get", "deployments", "-n", e,
             "-l", "managed-by=idp-cli",
             "--no-headers",
             "-o", "custom-columns=NAME:.metadata.name,READY:.status.readyReplicas,DESIRED:.spec.replicas,IMAGE:.spec.template.spec.containers[0].image"],
            capture_output=True, text=True
        )

        color_map = {"dev": "blue", "staging": "yellow", "prod": "green"}
        click.echo(f"  {click.style(e.upper(), fg=color_map[e], bold=True)}")

        if not result.stdout.strip():
            click.echo("    (no apps deployed)\n")
            continue

        click.echo(f"    {'NAME':<20} {'READY':<8} {'DESIRED':<10} IMAGE")
        click.echo(f"    {'─'*60}")
        for line in result.stdout.strip().split("\n"):
            if line:
                parts = line.split()
                name    = parts[0] if len(parts) > 0 else "-"
                ready   = parts[1] if len(parts) > 1 else "0"
                desired = parts[2] if len(parts) > 2 else "-"
                image   = parts[3] if len(parts) > 3 else "-"
                ready_int = int(ready) if ready.isdigit() else 0
                des_int   = int(desired) if desired.isdigit() else 0
                color     = "green" if ready_int == des_int and des_int > 0 else "red"
                click.echo(f"    {click.style('●', fg=color)} {name:<19} {ready:<8} {desired:<10} {image}")
        click.echo("")
