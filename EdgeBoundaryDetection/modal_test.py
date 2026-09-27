import modal

app = modal.App("edge-boundary-gpu-test")

image = modal.Image.debian_slim().pip_install("torch")


@app.function(
    image=image,
    gpu="T4",
    timeout=300,
)
def test_gpu():
    import torch

    print("=" * 50)
    print("CUDA available:", torch.cuda.is_available())

    if torch.cuda.is_available():
        print("GPU:", torch.cuda.get_device_name(0))
        print("CUDA version:", torch.version.cuda)

        x = torch.randn(5000, 5000, device="cuda")
        y = x @ x

        print("Tensor device:", y.device)
        print("GPU test: SUCCESS")
    else:
        print("GPU test: FAILED")


@app.local_entrypoint()
def main():
    test_gpu.remote()