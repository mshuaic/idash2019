import pytest


def pytest_addoption(parser):
    parser.addoption(
        "--size", action="store", default=None, type=int, help="my option: type1 or type2"
    )


@pytest.fixture
def size(request):
    return request.config.getoption("--size")
