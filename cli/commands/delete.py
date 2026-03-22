import click
import subprocess
import sys


@click.command()
@click.option("--app", required=True, help="Application name")
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
@click.option("--yes", is_flag=True,  help="Skip confirmation")
def delete(app, env, yes):
    """🗑️  Delete an application from the platform."""

    if not yes:
        click.confirm(
            f"\n  ⚠️  Delete {click.style(app, fg='red', bold=True)} from {click.style(env, fg='yellow', bold=True)}?",
            abort=True
        )

    click.echo(f"\n  🗑️  Deleting {app} from {env}...")

    for resource in ["deployment", "service"]:
        result = subprocess.run(
            ["kubectl", "delete", resource, app, "-n", env, "--ignore-not-found"],
            capture_output=True, text=True
        )
        if result.stdout.strip():
            click.echo(f"  {result.stdout.strip()}")

    click.echo(f"\n  ✅ {click.style(f'{app} deleted from {env}', fg='green')}\n")
