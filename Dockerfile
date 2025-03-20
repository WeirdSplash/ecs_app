# Usar una imagen base oficial de Python
FROM python:3.9

# Establecer el directorio de trabajo
WORKDIR /app

# Copiar los archivos de la aplicación y requerimientos
COPY ./src /app
COPY requirements.txt /app

# Instalar dependencias
RUN pip install --no-cache-dir -r requirements.txt

# Exponer el puerto 8080
EXPOSE 8080

# Comando para iniciar la aplicación
CMD ["python", "app.py"]
