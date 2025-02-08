# AI Open Bullet

AI Open Bullet is a Django-based web application designed to generate OpenBullet configuration files using AI models. This project allows users to upload training and configuration files, select AI models, and generate configuration files in LoliScript format. 

## Features

- **User Authentication**: Secure user login and registration.
- **User Profiles**: Manage user profiles with additional information.
- **File Management**: Upload and manage training and configuration files.
- **Caching**: Improve performance with caching mechanisms.
- **HAR File Processing**: Generate OpenBullet configuration files from HAR (HTTP Archive) files.
- **Responsive Design**: Mobile-friendly and responsive web interface.
- **Monitoring**: Admin page to monitor system health and activities.
- **Admin Panel**: Manage users, uploaded files, and AI models through a dedicated admin panel.

## Installation

Follow these steps to set up the AI Open Bullet web application on your server.

### Prerequisites

- Python 3.8 or higher
- pip (Python package installer)
- virtualenv
- Nginx
- Redis

### Step-by-Step Installation

1. **Clone the Repository**

    ```bash
    git clone https://github.com/Lucky7897/AI-open-bullet.git
    cd AI-open-bullet
    ```

2. **Run the Installation Script**

    The installation script `install.sh` will set up the virtual environment, install dependencies, configure the Django project, and set up Gunicorn and Nginx.

    ```bash
    chmod +x install.sh
    ./install.sh
    ```

    The script will:

    - Update the system packages.
    - Install Python, pip, virtualenv, and Nginx.
    - Set up the Django project and app.
    - Configure Django settings.
    - Create the necessary database migrations.
    - Set up Gunicorn as the application server.
    - Configure Nginx as a reverse proxy.

3. **Access the Application**

    Once the installation is complete, you can access the application via your server's IP address or domain.

    ```plaintext
    http://your-server-ip/
    ```

    The admin panel is accessible at:

    ```plaintext
    http://your-server-ip/admin
    ```

    Use the default admin credentials created during the installation:

    - Username: `admin`
    - Password: `adminpass`

## Usage

### Upload Training and Configuration Files

1. **Login** to the application.
2. **Upload** training files and configuration files via the web interface.
3. **Generate** OpenBullet configuration files by selecting an AI model and providing the necessary inputs.

### Generate Config from HAR Files

1. **Upload** a HAR file through the "Create Config from HAR File" form.
2. **Download** the generated configuration file in LoliScript format.

## Development

### Setting Up the Development Environment

1. **Clone the Repository**

    ```bash
    git clone https://github.com/Lucky7897/AI-open-bullet.git
    cd AI-open-bullet
    ```

2. **Create a Virtual Environment**

    ```bash
    python3 -m venv venv
    source venv/bin/activate
    ```

3. **Install Dependencies**

    ```bash
    pip install -r requirements.txt
    ```

4. **Run Migrations**

    ```bash
    python manage.py makemigrations
    python manage.py migrate
    ```

5. **Run the Development Server**

    ```bash
    python manage.py runserver
    ```

### Running Tests

1. **Run Tests**

    ```bash
    python manage.py test
    ```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
