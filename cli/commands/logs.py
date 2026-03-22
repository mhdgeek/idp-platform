import click
import subprocess


@click.command()
@click.option("--app",    required=True, help="Application name")
@click.option("--env",    required=True, type=click.Choice(["dev", "staging", "prod"]))
@click.option("--lines",  default=50,    help="Number of lines (default: 50)")
@click.option("--follow", is_flag=True,  help="Follow log output")
def logs(app, env, lines, follow):
    """📜 Stream application logs."""

    click.echo(f"\n  📜 Logs: {click.style(app, fg='cyan', bold=True)} / {click.style(env, fg='yellow', bold=True)}\n")

    cmd = ["kubectl", "logs", "-n", env, "-l", f"app={app}",
           f"--tail={lines}", "--max-log-requests=10"]

    if follow:
        cmd.append("-f")

    subprocess.run(cmd)
