import json
import re
import subprocess
import time
from datetime import datetime
from pathlib import Path
from tempfile import mkstemp
import os
import os

# Function to read the .env file and return a dictionary of environment variables
def load_env_file(file_path):
    env_vars = {}
    try:
        with open(file_path, 'r') as f:
            for line in f:
                # Ignore comments and empty lines
                if line.strip() and not line.startswith('#'):
                    key, value = line.strip().split('=', 1)
                    env_vars[key] = value.strip('"').strip("'")  # Handle quotes around values
    except FileNotFoundError:
        print(f".env file not found at {file_path}.")
    return env_vars

# Path to your .env file
env_file_path = "/app/.env"

# Load the environment variables from the .env file
env_vars = load_env_file(env_file_path)

# Get VPN credentials from the .env file
vpn_username = env_vars.get("VPN_USERNAME")
vpn_password = env_vars.get("VPN_PASSWORD")

# Ensure the username and password are loaded correctly
if not vpn_username or not vpn_password:
    raise ValueError("VPN username and/or password not found in the .env file.")

# Now you can use vpn_username and vpn_password as needed
print(f"VPN Username: {vpn_username}")
print(f"VPN Password: {vpn_password}")



# Ensure the username and password are loaded correctly
if not vpn_username or not vpn_password:
    raise ValueError("VPN username and/or password not found in the .env file.")

# Define the directory path
temp_test_dir = "/test_tmp"

# Create the directory
os.makedirs(temp_test_dir, exist_ok=True)

# Path to the authentication file
auth_file_path = '/config/credentials.txt'

# Create a dummy auth file with the loaded credentials
with open(auth_file_path, "w") as auth_file:
    auth_file.writelines([f"{vpn_username}\n", f"{vpn_password}\n"])
print(f"Created auth file at {auth_file_path} with username and password.")

# Base directory for OpenVPN config files
base_dir = "/etc/openvpn"
openvpn_config_paths = Path(base_dir).rglob("*.ovpn")
number_of_configs = len(list(openvpn_config_paths))

# Initialize the results dictionary
results = {"providers": {}}
count = 0



number_of_configs = len(list(Path(base_dir).rglob("*.ovpn")))
print(f"Total OpenVPN configurations found: {number_of_configs}")

if number_of_configs == 0:
    print("No OpenVPN configurations found. Exiting.")
    exit(1)




# Loop through each OpenVPN config file
for config_path in Path(base_dir).rglob("*.ovpn"):
    provider = config_path.relative_to(base_dir).parts[0]
    config = config_path.relative_to(Path(base_dir).joinpath(provider))

    if provider not in results["providers"]:
        results["providers"][provider] = {}

    if( provider != 'expressvpn2' ):
        continue

    print(f"========================================================")
    print(f"Testing VPN provider {provider}")
    print(f"VPN Username: {vpn_username}")
    print(f"VPN Password: {vpn_password}")

    # TODO: Remove. Initial testing, do max 10 configs per provider
    if len(results["providers"][provider].keys()) >= 2:
        continue

    print(f"Testing number {count} of {number_of_configs}")
    start = time.perf_counter()
    try:
        process = subprocess.run(
            [
                "openvpn",
                "--config",
                config_path,
                "--auth-user-pass",
                auth_file_path,
                "--connect-timeout",
                "3",
                "--resolv-retry",
                "1",
                "--connect-retry-max",
                "1",
                "--dev", 
                "tun",
            ],
            capture_output=True,
            timeout=10,
            encoding="UTF-8",
        )
    except Exception:
        server_responded = False
        auth_failed = None
        resolve_error = None
        retry_max = None
    else:
        server_responded = True if "Peer Connection Initiated" in process.stdout else False
        auth_failed = True if "AUTH_FAILED" in process.stdout else False
        resolve_error = (
            True if "RESOLVE: Cannot resolve host address" in process.stdout else False
        )

        retry_max_regex = re.compile(
            "All connections have been connect-retry-max .* times unsuccessful, exiting"
        )
        retry_max = True if retry_max_regex.search(process.stdout) else False

        print(process.stdout)

    stop = time.perf_counter()

    # Store results
    results["providers"][provider][str(config)] = {}
    results["providers"][provider][str(config)]["responded"] = server_responded
    results["providers"][provider][str(config)]["auth_failed"] = auth_failed
    results["providers"][provider][str(config)]["retry_max"] = retry_max
    results["providers"][provider][str(config)]["resolve_error"] = resolve_error
    results["providers"][provider][str(config)]["duration"] = round(stop - start, 2)
    count += 1

# Collect results summary
results["summary"] = {}



for provider in results["providers"]:
    successful_connects = 0
    provider_duration = 0.0
    for config in results["providers"][provider]:
        provider_duration += results["providers"][provider][config]["duration"]
        if results["providers"][provider][config]["responded"]:
            successful_connects += 1
    total_configs = len(results["providers"][provider].keys())
    rate = round(successful_connects / total_configs, 2) if total_configs > 0 else 0

    results["summary"][provider] = {
        "total": total_configs,
        "success": successful_connects,
        "duration": provider_duration,
        "rate": rate,
    }

# Save results to a JSON file with a timestamp
timestamp = datetime.now().strftime("%d%m%Y%H%M")
result_file_path = f"/test_tmp/result{timestamp}.json"
with open(result_file_path, "w") as outfile:
    json.dump(results, outfile, indent=4, sort_keys=True)

print(f"Results saved to {result_file_path}")
