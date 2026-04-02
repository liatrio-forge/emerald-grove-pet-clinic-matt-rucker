package org.springframework.samples.petclinic.owner;

import java.time.LocalDate;
import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.DisabledInNativeImage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.test.context.aot.DisabledInAotMode;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.hasSize;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(UpcomingVisitsController.class)
@DisabledInNativeImage
@DisabledInAotMode
class UpcomingVisitsControllerTests {

	@Autowired
	private MockMvc mockMvc;

	@MockitoBean
	private VisitRepository visits;

	private Visit sampleVisit() {
		Visit visit = new Visit();
		visit.setId(1);
		visit.setDate(LocalDate.now().plusDays(1));
		visit.setDescription("Checkup");
		Pet pet = new Pet();
		pet.setName("Max");
		Owner owner = new Owner();
		owner.setFirstName("George");
		owner.setLastName("Franklin");
		owner.addPet(pet);
		visit.setPet(pet);
		return visit;
	}

	@BeforeEach
	void setup() {
		given(this.visits.findUpcomingVisits(any(LocalDate.class), any(LocalDate.class), any(Pageable.class)))
			.willReturn(new PageImpl<>(List.of(sampleVisit())));
	}

	@Test
	void testUpcomingVisitsDefaultDays() throws Exception {
		mockMvc.perform(get("/visits/upcoming"))
			.andExpect(status().isOk())
			.andExpect(model().attributeExists("listVisits"))
			.andExpect(model().attribute("days", 7))
			.andExpect(view().name("visits/upcomingVisits"));
	}

	@Test
	void testUpcomingVisitsCustomDays() throws Exception {
		mockMvc.perform(get("/visits/upcoming").param("days", "14"))
			.andExpect(status().isOk())
			.andExpect(model().attribute("days", 14))
			.andExpect(view().name("visits/upcomingVisits"));
	}

	@Test
	void testUpcomingVisitsEmptyResult() throws Exception {
		given(this.visits.findUpcomingVisits(any(LocalDate.class), any(LocalDate.class), any(Pageable.class)))
			.willReturn(new PageImpl<>(List.of()));
		mockMvc.perform(get("/visits/upcoming"))
			.andExpect(status().isOk())
			.andExpect(model().attribute("listVisits", hasSize(0)))
			.andExpect(view().name("visits/upcomingVisits"));
	}

	@Test
	void testUpcomingVisitsPaginationContainsDays() throws Exception {
		mockMvc.perform(get("/visits/upcoming").param("days", "14").param("page", "1"))
			.andExpect(status().isOk())
			.andExpect(model().attribute("days", 14))
			.andExpect(model().attributeExists("currentPage"))
			.andExpect(model().attributeExists("totalPages"));
	}

	@Test
	void testUpcomingVisitsInvalidDaysFallback() throws Exception {
		mockMvc.perform(get("/visits/upcoming").param("days", "-1"))
			.andExpect(status().isOk())
			.andExpect(model().attribute("days", 7));
	}

	@Test
	void testUpcomingVisitsNonNumericDaysFallback() throws Exception {
		mockMvc.perform(get("/visits/upcoming").param("days", "abc"))
			.andExpect(status().isOk())
			.andExpect(model().attribute("days", 7));
	}

}
