#!/usr/bin/env python3
"""
IDP CLI — Internal Developer Platform
Deploy apps to Kubernetes with a single command.

Usage:
  idp deploy --app <name> --env <dev|staging|prod> --replicas <n>
  idp status --app <name> --env <dev|staging|prod>
  idp logs   --app <name> --env <dev|staging|prod>
  idp list
  idp delete --app <name> --env <dev|staging|prod>
"""
import click
from commands.deploy import deploy
from commands.status import status
from commands.logs import logs
from commands.list_apps import list_apps
from commands.delete import delete


@click.group()
@click.version_option(version="1.0.0")
def cli():
    """🚀 IDP — Internal Developer Platform CLI"""
    pass


cli.add_command(deploy)
cli.add_command(status)
cli.add_command(logs)
cli.add_command(list_apps, name="list")
cli.add_command(delete)

if __name__ == "__main__":
    cli()
