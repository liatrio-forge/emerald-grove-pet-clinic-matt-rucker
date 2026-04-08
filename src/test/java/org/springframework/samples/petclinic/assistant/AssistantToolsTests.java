/*
 * Copyright 2012-2025 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.springframework.samples.petclinic.assistant;

import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.samples.petclinic.owner.Owner;
import org.springframework.samples.petclinic.owner.OwnerRepository;
import org.springframework.samples.petclinic.owner.Pet;
import org.springframework.samples.petclinic.owner.PetType;
import org.springframework.samples.petclinic.owner.PetTypeRepository;
import org.springframework.samples.petclinic.owner.Visit;
import org.springframework.samples.petclinic.owner.VisitRepository;
import org.springframework.samples.petclinic.vet.Specialty;
import org.springframework.samples.petclinic.vet.Vet;
import org.springframework.samples.petclinic.vet.VetRepository;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;

/**
 * Unit tests for {@link AssistantTools} read-only tool methods.
 */
@ExtendWith(MockitoExtension.class)
class AssistantToolsTests {

	@Mock
	private OwnerRepository ownerRepository;

	@Mock
	private VetRepository vetRepository;

	@Mock
	private VisitRepository visitRepository;

	@Mock
	private PetTypeRepository petTypeRepository;

	private AssistantTools tools;

	@BeforeEach
	void setUp() {
		this.tools = new AssistantTools(this.ownerRepository, this.vetRepository, this.visitRepository,
				this.petTypeRepository);
	}

	// --- searchOwners ---

	@Test
	void searchOwnersShouldReturnFormattedResults() {
		Owner george = createOwner(1, "George", "Franklin", "Madison", "6085551023");
		given(this.ownerRepository.searchOwners(eq("Franklin"), eq(""), eq(""), any(Pageable.class)))
			.willReturn(new PageImpl<>(List.of(george)));

		String result = this.tools.searchOwners("Franklin", "", "");

		assertThat(result).contains("George Franklin");
		assertThat(result).contains("Madison");
		assertThat(result).contains("6085551023");
		assertThat(result).contains("/owners/1");
		assertThat(result).contains("1 owner(s)");
	}

	@Test
	void searchOwnersShouldReturnMessageWhenNoneFound() {
		given(this.ownerRepository.searchOwners(any(), any(), any(), any(Pageable.class))).willReturn(Page.empty());

		String result = this.tools.searchOwners("Nobody", "", "");

		assertThat(result).contains("No owners found");
	}

	// --- getOwnerDetails ---

	@Test
	void getOwnerDetailsShouldReturnOwnerWithPetsAndVisits() {
		Owner owner = createOwner(1, "George", "Franklin", "Madison", "6085551023");
		Pet max = createNewPet("Max", "dog", LocalDate.of(2020, 1, 1));
		Visit visit = new Visit();
		visit.setDate(LocalDate.of(2023, 1, 1));
		visit.setDescription("rabies shot");
		max.addVisit(visit);
		owner.addPet(max);
		max.setId(1);
		given(this.ownerRepository.findById(1)).willReturn(Optional.of(owner));

		String result = this.tools.getOwnerDetails(1);

		assertThat(result).contains("George Franklin");
		assertThat(result).contains("Madison");
		assertThat(result).contains("Max");
		assertThat(result).contains("dog");
		assertThat(result).contains("rabies shot");
		assertThat(result).contains("/owners/1");
	}

	@Test
	void getOwnerDetailsShouldReturnNotFoundMessage() {
		given(this.ownerRepository.findById(999)).willReturn(Optional.empty());

		String result = this.tools.getOwnerDetails(999);

		assertThat(result).contains("Owner not found");
	}

	// --- listVets ---

	@Test
	void listVetsShouldReturnFormattedVetsWithSpecialties() {
		Vet vet = new Vet();
		vet.setFirstName("James");
		vet.setLastName("Carter");
		Specialty radiology = new Specialty();
		radiology.setName("radiology");
		vet.addSpecialty(radiology);
		given(this.vetRepository.findAll()).willReturn(List.of(vet));

		String result = this.tools.listVets();

		assertThat(result).contains("Dr. James Carter");
		assertThat(result).contains("radiology");
	}

	@Test
	void listVetsShouldReturnMessageWhenNoneFound() {
		given(this.vetRepository.findAll()).willReturn(List.of());

		String result = this.tools.listVets();

		assertThat(result).contains("No veterinarians found");
	}

	// --- findVetsBySpecialty ---

	@Test
	void findVetsBySpecialtyShouldReturnMatchingVets() {
		Vet vet = new Vet();
		vet.setFirstName("Helen");
		vet.setLastName("Leary");
		given(this.vetRepository.findBySpecialtyName(eq("radiology"), any(Pageable.class)))
			.willReturn(new PageImpl<>(List.of(vet)));

		String result = this.tools.findVetsBySpecialty("radiology");

		assertThat(result).contains("Dr. Helen Leary");
		assertThat(result).contains("radiology");
	}

	@Test
	void findVetsBySpecialtyShouldReturnMessageWhenNoneFound() {
		given(this.vetRepository.findBySpecialtyName(eq("cardiology"), any(Pageable.class))).willReturn(Page.empty());

		String result = this.tools.findVetsBySpecialty("cardiology");

		assertThat(result).contains("No veterinarians found with specialty: cardiology");
	}

	// --- listPetTypes ---

	@Test
	void listPetTypesShouldReturnFormattedList() {
		PetType cat = new PetType();
		cat.setName("cat");
		PetType dog = new PetType();
		dog.setName("dog");
		given(this.petTypeRepository.findPetTypes()).willReturn(List.of(cat, dog));

		String result = this.tools.listPetTypes();

		assertThat(result).contains("cat");
		assertThat(result).contains("dog");
	}

	@Test
	void listPetTypesShouldReturnMessageWhenNoneFound() {
		given(this.petTypeRepository.findPetTypes()).willReturn(List.of());

		String result = this.tools.listPetTypes();

		assertThat(result).contains("No pet types found");
	}

	// --- getUpcomingVisits ---

	@Test
	void getUpcomingVisitsShouldReturnFormattedVisits() {
		Visit visit = new Visit();
		visit.setDate(LocalDate.now().plusDays(1));
		visit.setDescription("checkup");
		Pet pet = createPet(1, "Buddy", "dog", LocalDate.of(2021, 5, 1));
		Owner owner = createOwner(1, "Jane", "Doe", "Springfield", "5551234567");
		pet.addVisit(visit);
		// Set up pet's owner reference by adding to the owner
		visit.setPet(pet);

		given(this.visitRepository.findUpcomingVisits(any(LocalDate.class), any(LocalDate.class), any(Pageable.class)))
			.willReturn(new PageImpl<>(List.of(visit)));

		String result = this.tools.getUpcomingVisits(7);

		assertThat(result).contains("checkup");
		assertThat(result).contains("Buddy");
	}

	@Test
	void getUpcomingVisitsShouldReturnMessageWhenNoneFound() {
		given(this.visitRepository.findUpcomingVisits(any(LocalDate.class), any(LocalDate.class), any(Pageable.class)))
			.willReturn(Page.empty());

		String result = this.tools.getUpcomingVisits(7);

		assertThat(result).contains("No upcoming visits");
	}

	// --- createOwner ---

	@Test
	void createOwnerShouldSaveAndReturnSuccessMessage() {
		given(this.ownerRepository.save(any(Owner.class))).willAnswer(invocation -> {
			Owner saved = invocation.getArgument(0);
			saved.setId(42);
			return saved;
		});

		String result = this.tools.createOwner("Joe", "Bloggs", "123 Main St", "London", "1316761638");

		assertThat(result).contains("Owner created");
		assertThat(result).contains("Joe Bloggs");
		assertThat(result).contains("/owners/42");
	}

	@Test
	void createOwnerShouldRejectInvalidTelephone() {
		String result = this.tools.createOwner("Joe", "Bloggs", "123 Main St", "London", "123");

		assertThat(result).contains("Error");
		assertThat(result).contains("10 digits");
	}

	@Test
	void createOwnerShouldRejectNullTelephone() {
		String result = this.tools.createOwner("Joe", "Bloggs", "123 Main St", "London", null);

		assertThat(result).contains("Error");
	}

	// --- addPetToOwner ---

	@Test
	void addPetToOwnerShouldAddPetAndSave() {
		Owner owner = createOwner(1, "George", "Franklin", "Madison", "6085551023");
		PetType dog = new PetType();
		dog.setName("dog");
		given(this.ownerRepository.findById(1)).willReturn(Optional.of(owner));
		given(this.petTypeRepository.findPetTypes()).willReturn(List.of(dog));
		given(this.ownerRepository.save(any(Owner.class))).willReturn(owner);

		String result = this.tools.addPetToOwner(1, "Rex", "dog", "2021-03-15");

		assertThat(result).contains("Pet 'Rex' added");
		assertThat(result).contains("George Franklin");
		assertThat(result).contains("/owners/1");
	}

	@Test
	void addPetToOwnerShouldReturnErrorWhenOwnerNotFound() {
		given(this.ownerRepository.findById(999)).willReturn(Optional.empty());

		String result = this.tools.addPetToOwner(999, "Rex", "dog", "2021-03-15");

		assertThat(result).contains("Error");
		assertThat(result).contains("Owner not found");
	}

	@Test
	void addPetToOwnerShouldReturnErrorForUnknownPetType() {
		Owner owner = createOwner(1, "George", "Franklin", "Madison", "6085551023");
		PetType cat = new PetType();
		cat.setName("cat");
		given(this.ownerRepository.findById(1)).willReturn(Optional.of(owner));
		given(this.petTypeRepository.findPetTypes()).willReturn(List.of(cat));

		String result = this.tools.addPetToOwner(1, "Rex", "dragon", "2021-03-15");

		assertThat(result).contains("Error");
		assertThat(result).contains("Unknown pet type");
		assertThat(result).contains("dragon");
	}

	@Test
	void addPetToOwnerShouldReturnErrorForInvalidDate() {
		Owner owner = createOwner(1, "George", "Franklin", "Madison", "6085551023");
		PetType dog = new PetType();
		dog.setName("dog");
		given(this.ownerRepository.findById(1)).willReturn(Optional.of(owner));
		given(this.petTypeRepository.findPetTypes()).willReturn(List.of(dog));

		String result = this.tools.addPetToOwner(1, "Rex", "dog", "not-a-date");

		assertThat(result).contains("Error");
		assertThat(result).contains("Invalid date");
	}

	// --- bookVisit ---

	@Test
	void bookVisitShouldCreateVisitAndSave() {
		Owner owner = createOwner(1, "George", "Franklin", "Madison", "6085551023");
		Pet max = createNewPet("Max", "dog", LocalDate.of(2020, 1, 1));
		owner.addPet(max);
		max.setId(1);
		given(this.ownerRepository.findById(1)).willReturn(Optional.of(owner));
		given(this.ownerRepository.save(any(Owner.class))).willReturn(owner);

		String futureDate = LocalDate.now().plusDays(7).toString();
		String result = this.tools.bookVisit(1, 1, futureDate, "annual checkup");

		assertThat(result).contains("Visit booked");
		assertThat(result).contains("Max");
		assertThat(result).contains("annual checkup");
		assertThat(result).contains("/owners/1");
	}

	@Test
	void bookVisitShouldReturnErrorWhenOwnerNotFound() {
		given(this.ownerRepository.findById(999)).willReturn(Optional.empty());

		String result = this.tools.bookVisit(999, 1, "2025-06-15", "checkup");

		assertThat(result).contains("Error");
		assertThat(result).contains("Owner not found");
	}

	@Test
	void bookVisitShouldReturnErrorWhenPetNotFound() {
		Owner owner = createOwner(1, "George", "Franklin", "Madison", "6085551023");
		given(this.ownerRepository.findById(1)).willReturn(Optional.of(owner));

		String result = this.tools.bookVisit(1, 999, "2025-06-15", "checkup");

		assertThat(result).contains("Error");
		assertThat(result).contains("Pet not found");
	}

	@Test
	void bookVisitShouldReturnErrorForPastDate() {
		Owner owner = createOwner(1, "George", "Franklin", "Madison", "6085551023");
		Pet max = createNewPet("Max", "dog", LocalDate.of(2020, 1, 1));
		owner.addPet(max);
		max.setId(1);
		given(this.ownerRepository.findById(1)).willReturn(Optional.of(owner));

		String result = this.tools.bookVisit(1, 1, "2020-01-01", "checkup");

		assertThat(result).contains("Error");
		assertThat(result).contains("in the past");
	}

	@Test
	void bookVisitShouldReturnErrorForInvalidDate() {
		Owner owner = createOwner(1, "George", "Franklin", "Madison", "6085551023");
		Pet max = createNewPet("Max", "dog", LocalDate.of(2020, 1, 1));
		owner.addPet(max);
		max.setId(1);
		given(this.ownerRepository.findById(1)).willReturn(Optional.of(owner));

		String result = this.tools.bookVisit(1, 1, "bad-date", "checkup");

		assertThat(result).contains("Error");
		assertThat(result).contains("Invalid date");
	}

	// --- Helper methods ---

	private Owner createOwner(int id, String firstName, String lastName, String city, String telephone) {
		Owner owner = new Owner();
		owner.setId(id);
		owner.setFirstName(firstName);
		owner.setLastName(lastName);
		owner.setAddress("123 Main St");
		owner.setCity(city);
		owner.setTelephone(telephone);
		return owner;
	}

	private Pet createNewPet(String name, String typeName, LocalDate birthDate) {
		PetType type = new PetType();
		type.setName(typeName);
		Pet pet = new Pet();
		pet.setName(name);
		pet.setType(type);
		pet.setBirthDate(birthDate);
		return pet;
	}

	private Pet createPet(int id, String name, String typeName, LocalDate birthDate) {
		PetType type = new PetType();
		type.setName(typeName);
		Pet pet = new Pet();
		pet.setId(id);
		pet.setName(name);
		pet.setType(type);
		pet.setBirthDate(birthDate);
		return pet;
	}

}
