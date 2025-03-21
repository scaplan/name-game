from agents.agent import Agent

##  Author: Spencer Caplan
##  CUNY Graduate Center

class CB_Agent(Agent):
	def __init__(self, num, memlimit, initnamesdist, poprule, updaterule):
		super().__init__(num, memlimit, initnamesdist, poprule, updaterule)


	def __str__(self):
		return self.__class__.__name__ + " "+ super().__str__() + " DETSTATE: " + str(self.in_deterministic_state())


	def get_name(self):
		# randomly sample word from inventory (stored without frequency information)
		if len(self.memory) > 0:
			return self.get_random_name()
		else:
			return self.sample_initial_names_distro()


	def in_deterministic_state(self):
		if self.roundsplayed > 0 and len(self.memory) == 1:
			return True
		else:
			return False


	def compare_add_name(self, yourName, theirName):
		"""
		if my inventory contains the interlocutor's name then clear cache, and store only that name
		if my inventory does NOT contain the linterlocutor's name then add that name to inventory
		"""
		self.roundsplayed += 1

		# if theirName == yourName:
		if theirName in self.memory:
			self.memory = [theirName]
		else:
			self.memory_limit_check()
			self.memory = [theirName] + self.memory

