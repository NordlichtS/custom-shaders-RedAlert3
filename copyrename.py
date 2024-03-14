import os
import shutil

def find_and_copy_files():
    # Get the current directory
    current_directory = os.getcwd()

    # Find the first file with extension .fxo
    fxo_files = [file for file in os.listdir(current_directory) if file.endswith('.fxo')]
    if not fxo_files:
        print("No .fxo files found in the directory.")
        return

    original_file = fxo_files[0]
    print(f"Found this: {original_file}. Confirm copy? (Enter = confirm, X = cancel)")

    confirmation = input().strip()

    if confirmation.lower() == 'x':
        print("File copy canceled. Please Exit.")
        return
    elif confirmation != '':
        print("Invalid input. Please Restart Script.")
        return

    # Create a list of new filenames
    new_filenames = [
        'objectssoviet.fxo',
        'objectsallied.fxo',
        'objectsjapan.fxo',
        'objectsgeneric.fxo',
        'buildingssoviet.fxo',
        'buildingsallied.fxo',
        'buildingsjapan.fxo',
        'buildingsgeneric.fxo'
    ]

    # Copy and rename the original file 8 times
    for new_filename in new_filenames:
        new_file_path = os.path.join(current_directory, new_filename)
        shutil.copy(original_file, new_file_path)

    print("Files copied and renamed.")

if __name__ == "__main__":
    find_and_copy_files()
    input("Press any key to close the script and console.")
