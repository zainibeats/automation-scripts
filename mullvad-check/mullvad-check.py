import json
import sys
import subprocess

from logger import logger

# Runs mullvad check command and returns raw output
def mullvad_check() -> dict:
    logger.info("Running mullvad check...")
    cmd = ["curl", "https://am.i.mullvad.net/json"]
    raw_output = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
    )
    return raw_output.stdout

# Takes raw output from curl command and formats to dictionary
def format_output(raw_output) -> dict:
    data = json.loads(raw_output)
    return data

# Get and assign desired values to variables
def print_information_to_user(data) -> None:
    logger.info(f"IP: {data['ip']}")
    logger.info(f"City: {data['city']}")
    logger.info(f"Country: {data['country']}")
    logger.info(f"ISP: {data['organization']}")

# Main loop
if __name__ == "__main__":
    try:# Run mullvad check and return full output
        raw_output = mullvad_check()
        # Transform raw output to dict
        data = format_output(raw_output)
        # Displays ip, city, country and ISP
        print_information_to_user(data)
    except KeyboardInterrupt:
        logger.warning("\nCanceling script execution!")
        sys.exit(0)
