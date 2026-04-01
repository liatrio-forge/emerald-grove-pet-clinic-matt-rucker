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

package org.springframework.samples.petclinic.vet;

import java.util.List;

import org.assertj.core.util.Lists;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.DisabledInNativeImage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.http.MediaType;
import org.springframework.test.context.aot.DisabledInAotMode;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;

import static org.hamcrest.Matchers.hasSize;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Test class for the {@link VetController}
 */

@WebMvcTest(VetController.class)
@DisabledInNativeImage
@DisabledInAotMode
class VetControllerTests {

	@Autowired
	private MockMvc mockMvc;

	@MockitoBean
	private VetRepository vets;

	@MockitoBean
	private SpecialtyRepository specialties;

	private Specialty radiology() {
		Specialty radiology = new Specialty();
		radiology.setId(1);
		radiology.setName("radiology");
		return radiology;
	}

	private Vet james() {
		Vet james = new Vet();
		james.setFirstName("James");
		james.setLastName("Carter");
		james.setId(1);
		return james;
	}

	private Vet helen() {
		Vet helen = new Vet();
		helen.setFirstName("Helen");
		helen.setLastName("Leary");
		helen.setId(2);
		Specialty radiology = new Specialty();
		radiology.setId(1);
		radiology.setName("radiology");
		helen.addSpecialty(radiology);
		return helen;
	}

	@BeforeEach
	void setup() {
		given(this.vets.findAll()).willReturn(Lists.newArrayList(james(), helen()));
		given(this.vets.findAll(any(Pageable.class)))
			.willReturn(new PageImpl<Vet>(Lists.newArrayList(james(), helen())));
		given(this.specialties.findAll()).willReturn(Lists.newArrayList(radiology()));
	}

	@Test
	void testShowVetListHtml() throws Exception {

		mockMvc.perform(MockMvcRequestBuilders.get("/vets.html?page=1"))
			.andExpect(status().isOk())
			.andExpect(model().attributeExists("listVets"))
			.andExpect(view().name("vets/vetList"));

	}

	@Test
	void testShowResourcesVetList() throws Exception {
		ResultActions actions = mockMvc.perform(get("/vets").accept(MediaType.APPLICATION_JSON))
			.andExpect(status().isOk());
		actions.andExpect(content().contentType(MediaType.APPLICATION_JSON))
			.andExpect(jsonPath("$.vetList[0].id").value(1));
	}

	// === 1.1 Specialty Filter Acceptance Tests ===

	@Test
	void testFilterBySpecialty() throws Exception {
		given(this.vets.findBySpecialtyName(eq("radiology"), any(Pageable.class)))
			.willReturn(new PageImpl<>(List.of(helen())));
		mockMvc.perform(get("/vets.html?page=1&filter=radiology"))
			.andExpect(status().isOk())
			.andExpect(model().attributeExists("listVets"))
			.andExpect(model().attribute("listVets", hasSize(1)))
			.andExpect(view().name("vets/vetList"));
	}

	@Test
	void testFilterByNone() throws Exception {
		given(this.vets.findByNoSpecialties(any(Pageable.class))).willReturn(new PageImpl<>(List.of(james())));
		mockMvc.perform(get("/vets.html?page=1&filter=none"))
			.andExpect(status().isOk())
			.andExpect(model().attribute("listVets", hasSize(1)))
			.andExpect(view().name("vets/vetList"));
	}

	@Test
	void testNoFilterReturnsAllVets() throws Exception {
		mockMvc.perform(get("/vets.html?page=1"))
			.andExpect(status().isOk())
			.andExpect(model().attribute("listVets", hasSize(2)))
			.andExpect(view().name("vets/vetList"));
	}

	@Test
	void testUnrecognizedFilterFallsBackToAll() throws Exception {
		mockMvc.perform(get("/vets.html?page=1&filter=unknown"))
			.andExpect(status().isOk())
			.andExpect(model().attribute("listVets", hasSize(2)))
			.andExpect(view().name("vets/vetList"));
	}

	@Test
	void testModelContainsSpecialtiesAndCurrentFilter() throws Exception {
		given(this.vets.findBySpecialtyName(eq("radiology"), any(Pageable.class)))
			.willReturn(new PageImpl<>(List.of(helen())));
		mockMvc.perform(get("/vets.html?page=1&filter=radiology"))
			.andExpect(status().isOk())
			.andExpect(model().attributeExists("specialties"))
			.andExpect(model().attribute("currentFilter", "radiology"));
	}

	@Test
	void testJsonEndpointWithFilter() throws Exception {
		given(this.vets.findBySpecialtyName(eq("radiology"), any(Pageable.class)))
			.willReturn(new PageImpl<>(List.of(helen())));
		mockMvc.perform(get("/vets").param("filter", "radiology").accept(MediaType.APPLICATION_JSON))
			.andExpect(status().isOk())
			.andExpect(content().contentType(MediaType.APPLICATION_JSON))
			.andExpect(jsonPath("$.vetList", hasSize(1)));
	}

	// === End 1.1 Specialty Filter Acceptance Tests ===

	// === 2.1 Pagination Filter Preservation Tests ===

	@Test
	void testPaginationModelContainsFilterForLinks() throws Exception {
		given(this.vets.findBySpecialtyName(eq("radiology"), any(Pageable.class)))
			.willReturn(new PageImpl<>(List.of(helen())));
		mockMvc.perform(get("/vets.html?page=1&filter=radiology"))
			.andExpect(status().isOk())
			.andExpect(model().attribute("currentFilter", "radiology"))
			.andExpect(model().attributeExists("currentPage"))
			.andExpect(model().attributeExists("totalPages"));
	}

	@Test
	void testPaginationModelOmitsFilterWhenEmpty() throws Exception {
		mockMvc.perform(get("/vets.html?page=1"))
			.andExpect(status().isOk())
			.andExpect(model().attribute("currentFilter", ""));
	}

	// === End 2.1 Pagination Filter Preservation Tests ===

}
