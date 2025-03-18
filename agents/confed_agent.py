import random
from agents.agent import Agent


class Confed_Agent(Agent):
	def __init__(self, num, memlimit, initnamesdist, poprule, nametoseed):
		super().__init__(num, memlimit, initnamesdist, poprule, 'BUFFER')
		self.nametoseed = nametoseed
		self.active = False


	def __str__(self):
		return self.__class__.__name__ + " " + super().__str__() + " CONFED_ACTIVE: " + str(self.active)


	def activate_confed_agent(self):
		self.active = True


	def get_name(self):
		if self.active:
			return self.nametoseed
		else:
			return ''

	def check_is_confed(self):
		return True


	def add_single_name(self, newName):
		self.roundsplayed += 1
		self.memory_limit_check()
		self.memory = [newName] + self.memory



