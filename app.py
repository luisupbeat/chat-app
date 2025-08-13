from flask import Flask, render_template, request
from flask_socketio import SocketIO, emit

app = Flask(__name__)
app.config['SECRET_KEY'] = 'clave-secreta'
socketio = SocketIO(app)

# Guardaremos los usuarios como { sid: { username: str, avatar: str } }
usuarios = {}

@app.route('/')
def index():
    return render_template('index.html')

@socketio.on('register')
def manejar_registro(data):
    username = data.get('username', 'Desconocido')
    avatar = data.get('avatar', '')
    usuarios[request.sid] = {"username": username, "avatar": avatar}

    emit('presence', f"Usuario {username} conectado", broadcast=True)

@socketio.on('message')
def manejar_mensaje(msg):
    usuario = usuarios.get(request.sid, {"username": "Desconocido", "avatar": ""})
    emit('message', {
        "from": usuario["username"],
        "avatar": usuario["avatar"],
        "text": msg
    }, broadcast=True)

@socketio.on('disconnect')
def manejar_desconexion():
    usuario = usuarios.pop(request.sid, {"username": "Desconocido", "avatar": ""})
    emit('presence', f"Usuario {usuario['username']} desconectado", broadcast=True)

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=3000, debug=True)
