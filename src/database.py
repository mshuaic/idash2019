import abc


class Database(abc.ABC):
    @abc.abstractmethod
    def insert(self):
        pass

    @abc.abstractmethod
    def query(self):
        pass
