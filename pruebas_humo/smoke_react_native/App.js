import { useEffect, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { CameraView, useCameraPermissions } from 'expo-camera';

export default function App() {
  const [permission, requestPermission] = useCameraPermissions();
  const [ready, setReady] = useState(false);

  useEffect(() => {
    if (permission && !permission.granted) {
      requestPermission();
    }
  }, [permission]);

  if (!permission) {
    return (
      <View style={styles.container}>
        <Text>Cargando permisos de cámara...</Text>
      </View>
    );
  }

  if (!permission.granted) {
    return (
      <View style={styles.container}>
        <Text>Se necesita permiso para usar la cámara.</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <Text style={styles.title}>FixTrack - Prueba de cámara</Text>

      <CameraView
        style={styles.camera}
        facing="back"
        onCameraReady={() => setReady(true)}
      />

      <Text style={styles.status}>
        {ready ? 'Cámara funcionando correctamente' : 'Iniciando cámara...'}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#ffffff',
    paddingTop: 50,
  },
  title: {
    fontSize: 22,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 15,
  },
  camera: {
    flex: 1,
    marginHorizontal: 15,
    borderRadius: 15,
    overflow: 'hidden',
  },
  status: {
    textAlign: 'center',
    fontSize: 16,
    padding: 20,
  },
});