import os
import random
import shutil
import time
from xml.etree import ElementTree as ET
import subprocess
import pygetwindow as gw  # Install this via `pip install pygetwindow`

# Path to the META-INF folder and the application executable
META_INF_PATH = r"C:/RotMG-PrivateServer/RobotsInRealmMachineLearning/client/out/bin-debug/WebMain/META-INF/AIR/"

APP_EXECUTABLE = r"C:/RotMG-PrivateServer/RobotsInRealmMachineLearning/client/out/bin-debug/WebMain/betterSkillys.exe"

# XML file containing the `<id>`
XML_FILE = os.path.join(META_INF_PATH, "application.xml")

# Backup the original XML file (only once)
BACKUP_FILE = f"{XML_FILE}.bak"
if not os.path.exists(BACKUP_FILE):
    shutil.copy(XML_FILE, BACKUP_FILE)


def generate_unique_id(current_id):
    """Generate a unique ID using the current timestamp."""
    current_id += 1
    return f"betterSkillys{current_id}"

def update_application_id(xml_file, new_id):
    """Update the <id> value in the application.xml file."""
    # Parse the XML
    tree = ET.parse(xml_file)
    root = tree.getroot()
    namespace = {"air": "http://ns.adobe.com/air/application/32.0"}

    # Find and update the <id> element
    id_element = root.find("air:id", namespace)
    if id_element is not None:
        id_element.text = new_id
        tree.write(xml_file, encoding="utf-8", xml_declaration=True)
        print(f"Updated <id> to: {new_id}")
    else:
        raise ValueError("Unable to find <id> in the XML file.")

def restore_original_xml():
    """Restore the original XML file from the backup."""
    shutil.copy(BACKUP_FILE, XML_FILE)
    print("Restored the original XML file.")

def launch_app():
    """Launch the application."""
    print(f"Launching application: {APP_EXECUTABLE}")
    return subprocess.Popen([APP_EXECUTABLE], shell=True)

def set_window_position_and_size(title_contains, x, y, width, height):
    """Set the position and size of a window with a matching title."""
    time.sleep(1.25)  # Wait for the window to appear
    windows = gw.getWindowsWithTitle(title_contains)
    if not windows:
        print(f"No windows found with title containing: {title_contains}")
        return
    for window in windows:
        if title_contains in window.title:
            print(f"Setting window '{window.title}' to position ({x}, {y}) and size ({width}x{height})")
            window.moveTo(x, y)
            window.resizeTo(width, height)
            break


WINDOW_SIZE = 300  # Width and height of each window
WINDOW_COUNT = 5  # Total number of windows
GRID_COLUMNS = 3   # Number of columns in the grid

if __name__ == "__main__":
    for i in range(WINDOW_COUNT):
        print(f"Generating unique ID {i + 1}")
        try:
            # Generate a new unique ID
            unique_id = generate_unique_id(i)

            # Update the <id> in the XML file
            update_application_id(XML_FILE, unique_id)

            # Launch the application
            process = launch_app()

            # Calculate grid position
            row = i // GRID_COLUMNS
            col = i % GRID_COLUMNS
            x_position = col * WINDOW_SIZE
            y_position = row * WINDOW_SIZE

            set_window_position_and_size("betterSkillys",x=x_position, y=y_position, width=WINDOW_SIZE, height=WINDOW_SIZE)


        except Exception as e:
            print(f"An error occurred: {e}")


            # Restore the original XML file after launching
        restore_original_xml()
