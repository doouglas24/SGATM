package com.sgatm_db.aplicacao.repository;

import com.sgatm_db.aplicacao.model.Funcionario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface FuncionarioRepository extends JpaRepository<Funcionario, Long> {
    // Método para encontrar o funcionário pelo e-mail (usado no login)
    Funcionario findByEmail(String email);
}