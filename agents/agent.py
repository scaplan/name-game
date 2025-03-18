import random
from collections import Counter

"""
Abstract-ish superclass extended by different agent types (CB, BR, TP, etc.)

Setting FIFO_REMOVAL to True implements the queue-based memory model
While setting FIFO_REMOVAL to False implement the "bag" set-based memory model

"""
class Agent():
	def __init__(self, num, memlimit, initnamesdist, poprule, updaterule):
		self.roundsplayed = 0
		self.memory = []
		self.agentnum = num
		self.MEM_SIZE = memlimit
		self.init_names_list = initnamesdist

		if poprule == "FIFO":
			self.FIFO_REMOVAL = True
		elif poprule == "BAG":
			self.FIFO_REMOVAL = False
		else:
			raise Exception("Invalid argument to constructor; please specify either FIFO or BAG for the pop rule")
			
		if updaterule == "BUFFER":
			self.MISMATCH_DECREMENT = False
		elif updaterule == "PENALIZE":
			self.MISMATCH_DECREMENT = True
		else:
			raise Exception("Invalid argument to constructor; please specify either BUFFER or PENALIZE for the update rule")


	def __str__(self):
		assert len(self.memory) <= self.MEM_SIZE
		return "ID:" + str(self.agentnum) + " Rounds played: " + str(self.roundsplayed) + " Memory: " + ','.join(self.memory)

	def mem_to_str_semicolon(self):
		return ";".join(self.memory)


	def get_last_occurence_in_mem(self, nametofind):
		# search in reverse order
		# for i, name in enumerate(reversed(self.memory)): # remove random (essentially)
		# 	if name == nametofind:
		# 		return i
		# return -1
		for i in range(len(self.memory) - 1, -1, -1):
			if self.memory[i] == nametofind:
				return i
		return -1


	def seed_full_memory(self, nametoseed):
		self.memory = [nametoseed] * self.MEM_SIZE

	def seed_full_memory_fully_specified(self, fullmemory):
		self.memory = fullmemory

	def seed_single_name_memory(self, nametoseed):
		self.memory = [nametoseed]


	def memory_limit_check(self):
		while len(self.memory) >= self.MEM_SIZE:
			if self.FIFO_REMOVAL:
				self.memory.pop()
			else:
				# remove a random element rather than the least recent one
				upperbound = len(self.memory)-1
				self.memory.pop(random.randint(0,upperbound))


	def compare_add_name(self, yourName, theirName):
		"""
		This is the shared implementation to use unless overridden in subclasses
		e.g. CB agent overrides this to wipe memory upon mismatch

		General behavior:
			if the names are the same, then add. Subsequently popping out an item if exceeding M
			if the names are different, then eject a copy of the current agent's name and replace
		"""
		self.roundsplayed += 1

		if self.MISMATCH_DECREMENT:
			if yourName != theirName:
				# get index of last occurence of yourName to remove
				old_occurence_to_remove = self.get_last_occurence_in_mem(yourName)

				# only need to do this for the empirical data
				if old_occurence_to_remove != -1:
					self.memory.pop(old_occurence_to_remove)

		"""
		important to call memory_limit_check() *before* inserting the new name at the beginning of memory.
		otherwise the new name as the potentially be be accidentally popped out (if POP_RULE) is
		set to "BAG" rather than "FIFO"
		"""
		self.memory_limit_check()
		self.memory = [theirName] + self.memory



	def get_name(self):
		raise NotImplementedError()


	def in_deterministic_state(self):
		raise NotImplementedError()


	def check_is_confed(self):
		"""
		Assume no unless specifically set in confed_agent subclass
		"""
		return False

	def eval_name_trial(self, empirical_name):
		if self.get_name() == empirical_name:
			return 1
		else:
			return 0

	def sample_initial_names_distro(self):
		return random.choice(self.init_names_list)

	def get_most_frequent_name(self):
		assert len(self.memory) > 0 # can't get names from empty memory!
		c = Counter(self.memory)
		most_frequent_tuple = c.most_common()[0]
		most_frequent_type = most_frequent_tuple[0]
		return most_frequent_type


	def check_unique_plurality_item(self):
		if len(self.memory) == 0:
			return False
		count_list = list(Counter(self.memory).items())
		if len(count_list) == 1:
			return True
		if count_list[0][1] == count_list[1][1]:
			return False
		else:
			return True


	def get_random_name(self):
		assert len(self.memory) > 0 # can't get names from empty memory!
		return random.choice(self.memory)



