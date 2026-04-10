"""
Archivo WSGI para PythonAnywhere.

En la configuración de PythonAnywhere, apunta el Source code a este directorio
y el WSGI file debe importar la app así:

    import sys
    sys.path.insert(0, '/home/arocaalex/notova-api')
    from api import app as application
"""
from api import app as application
