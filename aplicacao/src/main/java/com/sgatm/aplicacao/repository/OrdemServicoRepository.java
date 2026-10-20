package com.sgatm_db.aplicacao.repository;

import com.sgatm_db.aplicacao.model.OrdemServico;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface OrdemServicoRepository extends JpaRepository<OrdemServico, Long> {

    // Método necessário para o filtro do relatório funcionar
    List<OrdemServico> findByStatus(String status);

}